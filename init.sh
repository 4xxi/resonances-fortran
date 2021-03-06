#!/bin/bash
git submodule init
git submodule update --recursive
cd mercury ;
sed -i -e 's/3000000.5d0/38982600.5d0/g' param.in.sample
make build && make gen-in;
cd ../axis ; make;
cp *.mod ../; cp *.mod ../librations/
cp global_parameters.mod ../astdys_adapter/;
cp global_parameters.mod ../mercury_adapter/;
cp global_parameters.mod ../librations/;

cd ../astdys_adapter ;
gfortran -O2 -c astdys_adapter.f90;
cp astdys_adapter.mod ../ ;
cd ../mercury_adapter ;
gfortran -O2 -c mercury_adapter.f90;
cp mercury_adapter.mod ../ ;
cd ../librations ;
gfortran -O2 -c simp_res_str.f90;
gfortran -O2 -c librations_support.f90;
gfortran -O2 -c librations.f90;
cp librations.mod ../;
cd ../
gfortran -O2 axis/*.o astdys_adapter/*.o mercury_adapter/*.o librations/*.o compositor.f90 -o comp.x;

mkdir -p input
mkdir -p output/aei
mkdir -p output/aei_planets
mkdir -p output/id_matrices
mkdir -p output/results
