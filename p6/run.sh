#!/bin/bash
perl6 client.pl 2>errs
SUCCESS=$?
if [ $SUCCESS -ne 0 ] ; then
    reset
    cat errs
    rm errs
fi
exit $SUCCESS
