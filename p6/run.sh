#!/bin/bash
perl6 client.pl 2>errs
SUCCESS=$?
if [ -s errs ] ; then
    reset
    cat errs
    rm errs
fi
exit $SUCCESS
