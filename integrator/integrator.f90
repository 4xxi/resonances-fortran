module integrator

use global_parameters, only : pwd
implicit none

type orb_elem
    character(25)::name
    real(8),dimension(6)::elem
end type orb_elem

type orb_elem_leaf
    type(orb_elem):: item
    type(orb_elem_leaf),pointer:: next
end type orb_elem_leaf

type orb_elem_list
    integer:: listlen
    type(orb_elem_leaf),pointer:: first
    type(orb_elem_leaf),pointer:: current
end type orb_elem_list

type argleaf
    ! Argument list item
    character(25)::name
    type(argleaf),pointer::next
end type argleaf

type arglist
    ! Argument list
    integer:: listlen
    type(argleaf),pointer::first
    type(argleaf),pointer::current
end type arglist


integer:: kmax=1000

contains

integer function find_asteroid(sample,f2,nrec,st) result(flag)
!# Find orbital elements for a given asteroid.
!# Given:
!#   i - <string> asteroid name
!#   f2 - file object for the source file
!#   nrec - number of records in the source file
!#   stlen - record length of the source file (must be constant)
!# Returns:
!#   st - <list> the corresponding record to a given asteroid
!#           (if no records found, returns None)
integer f2,nrec
character(25)::sample
type(orb_elem):: st
integer a,z,o
!    write(*,*)'Seeking record about ',sample
    flag=1
    a=1; z=nrec
    read(9,rec=a) st
    if (st%name == sample) then
        write(*,*) 'Found record: '
!        write(*,*) st
        write(*,*) 'at position ',a
        flag=0
        return
    endif
    read(9,rec=z) st
    if (st%name == sample) then
        write(*,*) 'Found record: '
!        write(*,*) st
        write(*,*) 'at position ',z
        flag=0
        return
    endif
    do while (z-a>1)
        o=(z+a)/2
        read(9,rec=o) st
        if (st%name == sample) then
            write(*,*) 'Found record: '
!            write(*,*) st
            write(*,*) 'at position ',o
            flag=0
            exit
        else
            if (st%name > sample) then
                z=o
            else
                a=o
            endif
        endif
    enddo
    if (flag==1) write(*,*) '...Not found any record about ',sample
    return
end function find_asteroid


subroutine mercury_processing(element_list)
    integer i,j,s,block_counter,flag
    type(orb_elem_list):: element_list

    write(*,*) '... Creating .aei files for a given subset...'
    element_list%current=>element_list%first
    block_counter=element_list%listlen / kmax
    do j=0,block_counter
        open(unit=8,file=trim(pwd)//'mercury/small.in',status='replace')
        write(8,'(a)') ')O+_06 Small-body initial data  (WARNING: Do not delete this line!!)'
        write(8,'(a)') ") Lines beginning with `)' are ignored."
        write(8,'(a)') ')---------------------------------------------------------------------'
        write(8,'(a)') 'style (Cartesian, Asteroidal, Cometary) = Asteroidal'
        write(8,'(a)') ')--------------------------------------------d or D is not matter--0d0 is possible too--'
        flag=0
        c2: do i=j*kmax+1,min((j+1)*kmax,element_list%listlen)
            open(unit=110,file=trim(pwd)//'aeibase/'//trim(element_list%current%item%name)//'.aei',&
                action='read',iostat=s)
            if(s==0) then
                write(*,*) 'Asteroid ',element_list%current%item%name," doesn't need an integration"
                close(110)
                element_list%current=>element_list%current%next
                cycle c2
            endif
            write(8,*) element_list%current%item%name,' ep=2457600.5d0'
            write(8,*) element_list%current%item%elem(1),element_list%current%item%elem(2),&
                       element_list%current%item%elem(3),element_list%current%item%elem(5),&
                       element_list%current%item%elem(4),element_list%current%item%elem(6),&
                       ' 0d0 0d0 0d0'
            flag=flag+1
            element_list%current=>element_list%current%next
        enddo c2
        close(8)
        if(flag>0) then
            write(*,*) 'Starting integration of a ',j,' block of asteroids'
            call execute_command_line('cd '//trim(pwd)//'mercury; '// &
                "time ./mercury6; time ./element6",wait=.true.)
            call execute_command_line('cd '//trim(pwd)//'mercury; '// &
                "mv *.aei ../aeibase/; mv info* ../ ; ./simple_clean.sh",wait=.true.)
        endif
    enddo
    write(*,*) '   .aei files created.'    
end subroutine mercury_processing


end module integrator
! open(unit=8,file='asteroids_format.csv',action='read')
! open(unit=9,file='asteroids.bin',access='direct',recl=sizeof(scr),status='replace')
! 
! n=0
! do
!     read(8,*,iostat=s) scr
!     if(s/=0) exit
!     n=n+1
!     write(9,rec=n) scr
! enddo
! close(8)
! close(9)