#/bin/sh

## TEST_DIR : path to the riscv-tests directory

ISA_DIR=$TEST_DIR/isa
SIM=./obj_dir/vtest

NTESTS=0
NFAIL=0

### test failed if printed.
for file in `find $ISA_DIR -maxdepth 1 -type f`; do
    if [ -x ""$file -a `echo $file | grep -- "rv32ui-p-"` ]; then
        NTESTS=$(($NTESTS + 1))
        #output="test $file .. "
        result=`$SIM $file 2> /dev/null`
        #echo $result
        `echo $result | grep -q "a0 : 00000000, a7 : 0000005d"`
        if [ $? -ne 0 ]; then
            NFAIL=$(($NFAIL + 1))
            echo $file
        fi
    fi
done

NCORRECT=$(($NTESTS - $NFAIL))
echo "ran $NTESTS test cases. $NCORRECT passed. $NFAIL failed."
