#!/usr/bin/perl
# Run the bootstrap hooks in scripts/bootstrap.d/ in lexical order.
#
# A hook is an executable file named NN-slug (e.g. 20-brew-env). The
# contract every hook must honor:
#
#   - idempotent: safe to run any number of times; detect "already
#     applied" and exit 0 without side effects
#   - bounded: finishes well inside the per-hook timeout (default below;
#     a hook doing legitimately long work may raise its own limit with a
#     "# bootstrap-timeout: <seconds>" line in its header)
#   - exit 0 = applied (or already applied)
#     exit 2 = skipped (a prerequisite is missing on this machine)
#     other  = failed
#
# The driver runs every hook even after one fails, kills a hook that
# exceeds the timeout (TERM, then KILL), and exits non-zero if any hook
# failed. Hooks run with cwd=$HOME and inherit the environment; they are
# not process-group-isolated, so an interactive sudo prompt still works.
#
# Environment:
#   BOOTSTRAP_TIMEOUT  seconds allowed per hook; overrides both the
#                      default (300) and any per-hook declaration

use strict;
use warnings;
use Cwd qw(abs_path);
use POSIX qw(WNOHANG);

$SIG{INT}  = sub { exit 130 };
$SIG{TERM} = sub { exit 143 };

# Keep driver and hook output in order (hooks write straight to the fd).
$| = 1;

if (@ARGV) {
    print STDERR "usage: bootstrap.pl (takes no arguments)\n";
    exit 2;
}

my $home = $ENV{HOME};
if (!defined $home || $home eq '' || !-d $home) {
    print STDERR "bootstrap: HOME is not set to a directory\n";
    exit 1;
}

my $env_timeout = $ENV{BOOTSTRAP_TIMEOUT};
if (defined $env_timeout && $env_timeout !~ /^[1-9][0-9]*$/) {
    print STDERR "bootstrap: BOOTSTRAP_TIMEOUT must be a positive integer\n";
    exit 1;
}

# Hooks live next to this script, so the driver works from any checkout
# (including a throwaway HOME); resolve before changing directory.
(my $script_dir = $0) =~ s{[^/]*$}{};
$script_dir = '.' if $script_dir eq '';
my $hooks_dir = abs_path("$script_dir/bootstrap.d");
if (!defined $hooks_dir || !-d $hooks_dir) {
    print STDERR "bootstrap: no bootstrap.d directory next to $0\n";
    exit 1;
}

chdir $home or do {
    print STDERR "bootstrap: cannot chdir to $home: $!\n";
    exit 1;
};

opendir(my $dh, $hooks_dir) or do {
    print STDERR "bootstrap: cannot open $hooks_dir: $!\n";
    exit 1;
};
my @entries = sort grep { !/^\./ } readdir $dh;
closedir $dh;

my (@ok, @skipped, @failed);
for my $name (@entries) {
    my $path = "$hooks_dir/$name";
    if ($name !~ /^[0-9][0-9]-[A-Za-z0-9][A-Za-z0-9._-]*$/ || !-f $path) {
        print STDERR
            "bootstrap: ignoring $name (hooks are files named NN-slug)\n";
        next;
    }
    if (!-x $path) {
        print STDERR "bootstrap: FAIL $name: not executable\n";
        push @failed, $name;
        next;
    }
    print "bootstrap: run $name\n";
    my $timeout = hook_timeout($path);
    my $status  = run_hook($path, $timeout);
    if ($status == 0) {
        print "bootstrap: ok $name\n";
        push @ok, $name;
    }
    elsif ($status == 2) {
        print "bootstrap: skip $name\n";
        push @skipped, $name;
    }
    elsif ($status == 124) {
        print STDERR "bootstrap: FAIL $name: timed out after ${timeout}s\n";
        push @failed, $name;
    }
    else {
        print STDERR "bootstrap: FAIL $name: exit status $status\n";
        push @failed, $name;
    }
}

printf "bootstrap: %d ok, %d skipped, %d failed\n",
    scalar @ok, scalar @skipped, scalar @failed;
if (@failed) {
    print STDERR "bootstrap: failed: @failed\n";
    exit 1;
}
exit 0;

# The timeout for one hook: the BOOTSTRAP_TIMEOUT environment override
# wins, then a "# bootstrap-timeout: <seconds>" declaration in the hook's
# first 20 lines (malformed declarations are ignored), then the default.
sub hook_timeout {
    my ($path) = @_;
    return $env_timeout if defined $env_timeout;
    if (open(my $fh, '<', $path)) {
        for (1 .. 20) {
            last unless defined(my $line = <$fh>);
            return $1 if $line =~ /^#\s*bootstrap-timeout:\s*([1-9][0-9]*)\s*$/;
        }
        close $fh;
    }
    return 300;
}

# Run one hook, returning its exit status, 124 on timeout, or 128+signal
# when it died on a signal. The wait is a WNOHANG poll, not alarm-based:
# perl installs handlers with SA_RESTART, so an alarm cannot reliably
# interrupt a blocking waitpid.
sub run_hook {
    my ($path, $timeout) = @_;
    my $pid = fork;
    die "bootstrap: fork failed: $!\n" unless defined $pid;
    if ($pid == 0) {
        { exec {$path} $path }
        print STDERR "bootstrap: cannot exec $path: $!\n";
        POSIX::_exit(127);
    }
    if (reap($pid, $timeout)) {
        my $status = $?;
        return ($status & 127) ? 128 + ($status & 127) : $status >> 8;
    }
    # Timed out: terminate, escalating to KILL if TERM is ignored.
    kill 'TERM', $pid;
    return 124 if reap($pid, 5);
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return 124;
}

# Poll for the child to exit for up to $limit seconds; true if reaped
# (its wait status is left in $?).
sub reap {
    my ($pid, $limit) = @_;
    my $deadline = time() + $limit;
    while (1) {
        return 1 if waitpid($pid, WNOHANG) == $pid;
        return 0 if time() >= $deadline;
        select(undef, undef, undef, 0.2);
    }
}
