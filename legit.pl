#!/usr/bin/perl -w
use File::Copy;
use File::Path 'rmtree';
use File::Compare;
use Algorithm::Merge qw(merge diff3 traverse_sequences3);

# read current working branch
sub getwb {
    open my $f, '<', ".legit/workingbranch";
    my $wb = <$f>;
    return $wb;
}
# read current existing commits
sub getindex {
    my $index = -2;
    foreach my $commit (glob ".legit/commit/*") {
        $index ++;
    }
    return $index
}

# check whether one file is saved in branches
sub isbranched {
    my ($file) = @_;
    foreach my $branch (glob ".legit/branch/*") {
            $branch =~ s/\.legit\/branch\///;
            if (-e ".legit/branch/$branch/$file" && compare("$file", ".legit/branch/$branch/$file") == 0) {
                return 1;
        }
    }
    return 0;
}

# check whether one file is committed
sub iscommitted {
    my ($file) = @_;
    foreach my $commit (glob ".legit/commit/*") {
            $commit =~ s/\.legit\/commit\///;
            next if $commit eq "log";
            if (-e ".legit/commit/$commit/$file" && compare("$file", ".legit/commit/$commit/$file") == 0) {
                return 1;
        }
    }
    return 0;
}

# check whether one file is added in index
sub isindexed {
    my ($file) = @_;
    if (-e ".legit/index/$file" && compare("$file", ".legit/index/$file") == 0) {
        return 1;
    }
    return 0;
}

# merge based on Algorithm::Merge, return merged content in array
sub _merge{
    my ($fwb, $ftarget, $fcommon) = @_;
    open my $a, '<', "$fwb";
    my @f1 = <$a>;
    open my $b, '<', "$ftarget";
    my @f2 = <$b>;    
    open my $c, '<', "$fcommon";
    my @f3 = <$c>;    
    my @result = merge(\@f3, \@f2, \@f1, {
        CONFLICT => sub {die "legit.pl: error: These files can not be merged:\n$fwb\n"}
    });
    return @result
}

# init
if (length $ARGV[0] && $ARGV[0] eq "init") {
    ! -e ".legit" or die "legit.pl: error: .legit already exists\n";
    mkdir ".legit";
    mkdir ".legit/index";
    mkdir ".legit/commit";
    mkdir ".legit/branch";
    mkdir ".legit/commonbase";  # saving files in commonbase when making a new branch, works for merge function
    open my $f, '>', ".legit/workingbranch";    # workingbranch indicates which branch is working
    print $f "master";
    close $f;
    print "Initialized empty legit repository in .legit\n";

# add
} elsif (length $ARGV[0] && $ARGV[0] eq "add") {
    -e ".legit" or die "legit.pl: error: no .legit directory containing legit repository exists\n";
    shift @ARGV;
    foreach my $file (@ARGV) {
        (-e "$file" || -e ".legit/index/$file")  or die "legit.pl: error: can not open '$file'\n";
        $file =~ /^[a-zA-Z0-9]/ or die "legit.pl: error: invalid filename '$file'\n";
        my $fname = $file;
        $fname =~ s/[-_]//;
        $fname =~ s/\.//;
        ! ($fname =~ /\W/) or die "legit.pl: error: invalid filename '$file'\n";
    }
    foreach my $file (@ARGV) {
        next if $file eq "legit.pl";
        # remove the file from index if some deleted file is added 
        if (! -e "$file" && -e ".legit/index/$file") {
            unlink ".legit/index/$file";
            next;
        }
        copy("$file", ".legit/index/");
    }

# commit
} elsif (length $ARGV[0] && $ARGV[0] eq "commit"){
    ((@ARGV == 3 && $ARGV[1] eq "-m")||(@ARGV == 4 && $ARGV[1] eq "-a" && $ARGV[2] eq "-m")) or die "usage: legit.pl commit [-a] -m commit-message\n";
    # option -a
    if ($ARGV[1] eq "-a") {
        -e ".legit/commit/log" or die "nothing to commit\n";
        foreach my $file (glob ".legit/index/*"){
            my $fname = $file;
            $fname =~ s/\.legit\/index\///;
            if (-e $fname) {
                copy($fname, ".legit/index/");
            } 
        }
        shift @ARGV;
    }
    # commit 0 
    if (! -e ".legit/commit/log") {
        $wb = getwb();
        mkdir ".legit/commit/0";
        open my $m, '>', ".legit/commit/log";
        print $m "0 \"$ARGV[2]\" $wb\n";
        close $m;
        foreach my $file (glob ".legit/index/*") {
            copy("$file", ".legit/commit/0/");
            copy("$file", ".legit/branch/$wb/");
        }
        print "Committed as commit 0\n";
    } else {
    # compare the files, then compare the files' contents if the index and last commit have same files
        my $commit_flag = 0;
        my @c_array = ();
        my @i_array = ();
        $index = getindex();
        foreach my $file (glob ".legit/index/*") {
            $file =~ s/\.legit\/index\///;
            push @i_array, $file;
        }
        foreach my $file (glob ".legit/commit/$index/*") {
            $file =~ s/\.legit\/commit\/$index\///;
            push @c_array, $file;
        }
        $commit_flag = 1 if @i_array !=  @c_array;
        if ($commit_flag == 0) {
            foreach my $file (@i_array) {
                if (compare(".legit/index/$file", ".legit/commit/$index/$file") != 0) {
                    $commit_flag = 1;
                    last;
                }
            }
        }
        if ($commit_flag == 1) {
            my $wb = getwb();
            $index ++;
            mkdir ".legit/commit/$index";
            open my $m, '>>', ".legit/commit/log";
            print $m "$index \"$ARGV[2]\" $wb\n";
            close $m;
            foreach my $file (glob ".legit/index/*") {
                copy("$file", ".legit/commit/$index/");
                copy("$file", ".legit/branch/$wb/");
            }
            print "Committed as commit $index\n";
        } else {
            print "nothing to commit\n";
        }
    }
    
# log
} elsif (length $ARGV[0] && $ARGV[0] eq "log") {    # bug not fixed - cannot trace merged branches relations
    my $wb = getwb();
    open my $log, '<', ".legit/commit/log" or die "legit.pl: error: your repository does not have any commits yet\n";
    my @log = reverse <$log>;
    foreach my $line (@log) {
        if ($line =~ /(\S+) (".+") (.*)$/) {
            my $branch = $3;
            my $content = "$1 $2";
            $content =~ s/\"//g;
            print "$content\n";
        }       
    }   

# show    
} elsif (length $ARGV[0] && $ARGV[0] eq "show") {
    if (! length $ARGV[1]) {
        die "usage: legit.pl show <commit>:<filename>\n";
    }
    if ($ARGV[1] =~ /^(.*):(.*)$/) {
        my $commit = $1;
        my $file = $2;
        ! ($commit =~ /\D/) or die "legit.pl: error: unknown commit '$commit'\n";
        $file =~ /^[a-zA-Z0-9]/ or die "legit.pl: error: invalid filename '$file'\n";
        my $fname = $file;
        $fname =~ s/[-_]//;
        $fname =~ s/\.//;
        ! ($fname =~ /\W/) or die "legit.pl: error: invalid filename '$file'\n";
        if (! length $commit) {
            open my $f, '<', ".legit/index/$file" or die "legit.pl: error: '$file' not found in index\n";
            my @content = <$f>;
            print @content;
        } else {
            -e ".legit/commit/$commit" or die "legit.pl: error: unknown commit '$commit'\n";
            open my $f, '<', ".legit/commit/$commit/$file" or die "legit.pl: error: '$file' not found in commit $commit\n";       
            my @content = <$f>;
            print @content;
        }
    } else {
        print "legit.pl: error: invalid object $ARGV[1]\n";
    }
    
# rm
} elsif (length $ARGV[0] && $ARGV[0] eq "rm") {
    shift @ARGV;
    my $force = 0;
    my $cached = 0;
    if ($ARGV[0] eq '--force') {
        $force = 1;
        shift @ARGV;
    }
    if ($ARGV[0] eq '--cached') {
        $cached = 1;
        shift @ARGV;
    }
    if ($ARGV[0] eq '--force') {
        $force = 1;
        shift @ARGV;
    }
    my $commit_flag = 0;    
    $index = getindex();
    foreach my $file (@ARGV) {
        -e ".legit/index/$file" or die "legit.pl: error: '$file' is not in the legit repository\n";
    }    
    foreach my $file (@ARGV) {
        $eflag = 0;    # error flag for 3 cases of errors
        if ($force == 1) {
            unlink ".legit/index/$file";
            unlink "$file" if $cached == 0;
            next;
        }            
        if (-e ".legit/commit/$index/$file") {
            $eflag += 1 if compare(".legit/index/$file", ".legit/commit/$index/$file") != 0 && $cached == 0;
        }
        if (-e "$file") {
            if ($cached == 0) {
                -e ".legit/commit/$index/$file" or die "legit.pl: error: '$file' has changes staged in the index\n";
                $eflag += 2 if compare(".legit/index/$file", "$file") != 0;
            }
            if ($cached == 1) {
                $eflag = 3 if compare(".legit/index/$file", "$file") != 0 && compare(".legit/index/$file", ".legit/commit/$index/$file") != 0;
            }
        }
        $eflag != 1 or die "legit.pl: error: '$file' has changes staged in the index\n";
        $eflag != 2 or die "legit.pl: error: '$file' in repository is different to working file\n";
        $eflag != 3 or die "legit.pl: error: '$file' in index is different to both working file and repository\n";
        if ($force == 0) {
            unlink ".legit/index/$file";
            unlink "$file" if $cached == 0;   
        }
    }
    
# status
} elsif (length $ARGV[0] && $ARGV[0] eq "status") {
    if (-e ".legit/branch/master") {
        my $wb = getwb(); 
        foreach my $file (glob ".legit/branch/$wb/*") {
            $file =~ s/\.legit\/branch\/$wb\///;
            push @c_array, $file;
        }
        $path = ".legit/branch/$wb";
    } else {
        my $index = getindex();
        foreach my $file (glob ".legit/commit/$index/*") {
            $file =~ s/\.legit\/commit\/$index\///;
            push @c_array, $file;
        }
        $path = ".legit/commit/$index";
    }     
    foreach my $file (glob ".legit/index/*") {
        $file =~ s/\.legit\/index\///;
        push @i_array, $file;
    }
    foreach my $file (glob "*") {
        push @o_array, $file;
    }
    foreach my $file (@i_array) {
        if (grep $_ eq $file, @o_array) {
            if (compare (".legit/index/$file", "$file") == 0) {
                $status{$file} = "same as repo";
            } else {
                $status{$file} = "file changed, changes not staged for commit";
            }
        } else {
            $status{$file} = "file deleted";
        }
    }
    foreach my $file (@i_array) {
        if (grep $_ eq $file, @c_array) {
            if (compare (".legit/index/$file", "$path/$file") == 0) {
                $status{$file} = "file changed, changes not staged for commit" if $status{$file} ne "same as repo" && $status{$file} ne "file deleted";     
            } else {
                if ($status{$file} eq "same as repo") {
                    $status{$file} = "file changed, changes staged for commit" if $status{$file} ne "file deleted";
                } else {
                    $status{$file} = "file changed, different changes staged for commit" if $status{$file} ne "file deleted";
                }
            }
        } else {
            $status{$file} = "added to index" if $status{$file} ne "file deleted";
        }
    }
    foreach my $file (@c_array) {
        if (! grep $_ eq $file, @i_array) {
            $status{$file} = "deleted";
        }
    }
    foreach my $file (@o_array) {
        if (! grep $_ eq $file, @i_array) {
            $status{$file} = "untracked";
        }
        if (grep $_ eq $file, @i_array && grep $_ eq $file, @c_array) {
            $status{$file} = "same as repo" if compare("$file", "$path/$file") == 0;
        }
    }
    foreach $file (sort keys %status) {
        print "$file - $status{$file}\n";
    }
    
# branch
} elsif (length $ARGV[0] && $ARGV[0] eq "branch") {
    if (@ARGV == 1) {
        -e ".legit/branch/master" or die "legit.pl: error: your repository does not have any commits yet\n";
        foreach my $b (glob ".legit/branch/*") {
            $b =~ s/\.legit\/branch\///;
            print "$b\n";
        }
        exit 1;
    }
    if (@ARGV == 3 && $ARGV[1] eq "-d") {
        -e ".legit/branch/$ARGV[2]" or die "legit.pl: error: branch '$ARGV[2]' does not exist\n";
        $ARGV[2] ne "master" or die "legit.pl: error: can not delete branch 'master'\n";
        foreach my $file (glob ".legit/branch/$ARGV[2]/*") {
            $file =~ s/\.legit\/branch\/$ARGV[2]\///;
            iscommitted($file) or die "legit.pl: error: branch '$ARGV[2]' has unmerged changes\n";
        }
        rmtree(".legit/branch/$ARGV[2]");
        print "Deleted branch '$ARGV[2]'\n";
        exit 1;
    }
    ! -e ".legit/branch/$ARGV[1]" or die "legit.pl: error: branch '$ARGV[1]' already exists\n";
    # init master branch
    if (! -e ".legit/branch/master") {
        mkdir ".legit/branch/master";
        foreach my $file (glob "*") {
            next if $file eq "legit.pl" || $file eq ".legit";
            copy ("$file", ".legit/branch/master/");
        }       
    }
    mkdir ".legit/branch/$ARGV[1]";
    $wb = getwb();
    mkdir ".legit/commonbase/$wb\_$ARGV[1]";
    foreach my $file (glob "*") {
        next if $file eq "legit.pl" || $file eq ".legit";
        copy ("$file", ".legit/branch/$ARGV[1]/");
        copy ("$file", ".legit/commonbase/$wb\_$ARGV[1]/");
    }

# checkout    
} elsif (length $ARGV[0] && $ARGV[0] eq "checkout") {
    # checkout  step 1: modified existing files, overwritten files from branch if needed 
    #           step 2: modified existing files, removed files if needed 
    #           step 3: copy files from branch if needed   
    -e ".legit/branch/$ARGV[1]" or die "legit.pl: error: unknown branch '$ARGV[1]'\n";
    my $wb = getwb();
    my $index = getindex();
    open my $f2, '>', ".legit/workingbranch";
    print $f2 "$ARGV[1]";
    close $f2;
    foreach my $file (glob "*") {
        next if $file eq "legit.pl" || $file eq ".legit";
        if (-e ".legit/branch/$ARGV[1]/$file") {
            next if compare("$file", ".legit/branch/$ARGV[1]/$file") == 0; 
            if (isbranched($file)) { 
                copy (".legit/branch/$ARGV[1]/$file", "$file"); 
            } 
        } else {          
            unlink $file if iscommitted($file);            
        }      
    }
    foreach my $file (glob ".legit/branch/$ARGV[1]/*") {
        my $fname = $file;
        $fname =~ s/\.legit\/branch\/$ARGV[1]\///;
        copy ("$file", "./") if ! -e "$fname";
    }
    print "Switched to branch '$ARGV[1]'\n";
    
# merge
} elsif (length $ARGV[0] && $ARGV[0] eq "merge") {
    @ARGV > 3 or die "legit.pl: error: empty commit message\n";
    if ($ARGV[1] eq "-m") {
        $message = $ARGV[2];
        $bc = $ARGV[3];
    } else {
        $bc = $ARGV[1];
        $message = $ARGV[3];
    }
    -e ".legit/branch/$bc" or die "legit.pl: error: unknown branch '$bc'\n";
    $forward = 1;
    $index = getindex();
    $wb = getwb();
    $dir = "commit";
    $dir = "branch" if -e ".legit/branch/$bc";
    foreach my $file (glob ".legit/$dir/$bc/*") {
        $f = $file;
        $f =~ s/\.legit\/$dir\/$bc\///;
        if (! -e "$f") {
            copy ("$file", "./");
            next;
        }
        next if compare ("$file", "$f") == 0; 
        my @result = _merge("$f", "$file", ".legit/commonbase/$wb\_$bc/$f");
        open my $merge, '>', "$f";
        foreach my $line (@result) {
                print $merge "$line";
        }
        close $merge;
        copy("$f", ".legit/index/");
        $forward = 0 if compare("$f", "$file") != 0;
        print "Auto-merging $f\n";
    }
    if ($forward == 0) { 
        $index ++;
        mkdir ".legit/commit/$index";
        open my $m, '>>', ".legit/commit/log";
        print $m "$index \"$ARGV[2]\" $wb\n";
        close $m;
        foreach my $file (glob ".legit/index/*") {
            copy("$file", ".legit/commit/$index/");
            copy("$file", ".legit/branch/$wb/");
            }
        print "Committed as commit $index\n";
    } else {
        print "Fast-forward: no commit created\n";
    }

# usage message
} else { 
    print
"Usage: legit.pl <command> [<args>]

These are the legit commands:
    init       Create an empty legit repository
    add        Add file contents to the index
    commit     Record changes to the repository
    log        Show commit log
    show       Show file at particular state
    rm         Remove files from the current directory and from the index
    status     Show the status of files in the current directory, index, and repository
    branch     list, create or delete a branch
    checkout   Switch branches or restore current directory files
    merge      Join two development histories together\n"
}
