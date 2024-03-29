! include/40/omp_lib.h.var

! <copyright>
!    Copyright (c) 1985-2015 Intel Corporation.  All Rights Reserved.
!
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!
!      * Redistributions of source code must retain the above copyright
!        notice, this list of conditions and the following disclaimer.
!      * Redistributions in binary form must reproduce the above copyright
!        notice, this list of conditions and the following disclaimer in the
!        documentation and/or other materials provided with the distribution.
!      * Neither the name of Intel Corporation nor the names of its
!        contributors may be used to endorse or promote products derived
!        from this software without specific prior written permission.
!
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
!    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
!    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
!    HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
!    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
!    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
!    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
!    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
!    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
!    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
!
! </copyright>

!***
!*** Some of the directives for the following routine extend past column 72,
!*** so process this file in 132-column mode.
!***

!DIR$ fixedformlinesize:132

      integer, parameter :: omp_integer_kind       = 4
      integer, parameter :: omp_logical_kind       = 4
      integer, parameter :: omp_real_kind          = 4
      integer, parameter :: omp_lock_kind          = int_ptr_kind()
      integer, parameter :: omp_nest_lock_kind     = int_ptr_kind()
      integer, parameter :: omp_sched_kind         = omp_integer_kind
      integer, parameter :: omp_proc_bind_kind     = omp_integer_kind
      integer, parameter :: kmp_pointer_kind       = int_ptr_kind()
      integer, parameter :: kmp_size_t_kind        = int_ptr_kind()
      integer, parameter :: kmp_affinity_mask_kind = int_ptr_kind()
      integer, parameter :: kmp_lock_hint_kind     = omp_integer_kind

      integer (kind=omp_integer_kind), parameter :: openmp_version    = 201307
      integer (kind=omp_integer_kind), parameter :: kmp_version_major = 5
      integer (kind=omp_integer_kind), parameter :: kmp_version_minor = 0
      integer (kind=omp_integer_kind), parameter :: kmp_version_build = 20150401
      character(*)               kmp_build_date
      parameter( kmp_build_date = 'No Timestamp' )

      integer(kind=omp_sched_kind), parameter :: omp_sched_static  = 1
      integer(kind=omp_sched_kind), parameter :: omp_sched_dynamic = 2
      integer(kind=omp_sched_kind), parameter :: omp_sched_guided  = 3
      integer(kind=omp_sched_kind), parameter :: omp_sched_auto    = 4

      integer (kind=omp_proc_bind_kind), parameter :: omp_proc_bind_false = 0
      integer (kind=omp_proc_bind_kind), parameter :: omp_proc_bind_true = 1
      integer (kind=omp_proc_bind_kind), parameter :: omp_proc_bind_master = 2
      integer (kind=omp_proc_bind_kind), parameter :: omp_proc_bind_close = 3
      integer (kind=omp_proc_bind_kind), parameter :: omp_proc_bind_spread = 4

      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_none           = 0
      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_uncontended    = 1
      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_contended      = 2
      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_nonspeculative = 3
      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_speculative    = 4
      integer (kind=kmp_lock_hint_kind), parameter :: kmp_lock_hint_adaptive       = 5

      interface

!       ***
!       *** omp_* entry points
!       ***

        subroutine omp_set_num_threads(nthreads) bind(c)
          import
          integer (kind=omp_integer_kind), value :: nthreads
        end subroutine omp_set_num_threads

        subroutine omp_set_dynamic(enable) bind(c)
          import
          logical (kind=omp_logical_kind), value :: enable
        end subroutine omp_set_dynamic

        subroutine omp_set_nested(enable) bind(c)
          import
          logical (kind=omp_logical_kind), value :: enable
        end subroutine omp_set_nested

        function omp_get_num_threads() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_num_threads
        end function omp_get_num_threads

        function omp_get_max_threads() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_max_threads
        end function omp_get_max_threads

        function omp_get_thread_num() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_thread_num
        end function omp_get_thread_num

        function omp_get_num_procs() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_num_procs
        end function omp_get_num_procs

        function omp_in_parallel() bind(c)
          import
          logical (kind=omp_logical_kind) omp_in_parallel
        end function omp_in_parallel

        function omp_in_final() bind(c)
          import
          logical (kind=omp_logical_kind) omp_in_final
        end function omp_in_final

        function omp_get_dynamic() bind(c)
          import
          logical (kind=omp_logical_kind) omp_get_dynamic
        end function omp_get_dynamic

        function omp_get_nested() bind(c)
          import
          logical (kind=omp_logical_kind) omp_get_nested
        end function omp_get_nested

        function omp_get_thread_limit() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_thread_limit
        end function omp_get_thread_limit

        subroutine omp_set_max_active_levels(max_levels) bind(c)
          import
          integer (kind=omp_integer_kind), value :: max_levels
        end subroutine omp_set_max_active_levels

        function omp_get_max_active_levels() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_max_active_levels
        end function omp_get_max_active_levels

        function omp_get_level() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_level
        end function omp_get_level

        function omp_get_active_level() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_active_level
        end function omp_get_active_level

        function omp_get_ancestor_thread_num(level) bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_ancestor_thread_num
          integer (kind=omp_integer_kind), value :: level
        end function omp_get_ancestor_thread_num

        function omp_get_team_size(level) bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_team_size
          integer (kind=omp_integer_kind), value :: level
        end function omp_get_team_size

        subroutine omp_set_schedule(kind, modifier) bind(c)
          import
          integer (kind=omp_sched_kind), value :: kind
          integer (kind=omp_integer_kind), value :: modifier
        end subroutine omp_set_schedule

        subroutine omp_get_schedule(kind, modifier) bind(c)
          import
          integer (kind=omp_sched_kind) kind
          integer (kind=omp_integer_kind) modifier
        end subroutine omp_get_schedule

        function omp_get_proc_bind() bind(c)
          import
          integer (kind=omp_proc_bind_kind) omp_get_proc_bind
        end function omp_get_proc_bind

        function omp_get_wtime() bind(c)
          double precision omp_get_wtime
        end function omp_get_wtime

        function omp_get_wtick() bind(c)
          double precision omp_get_wtick
        end function omp_get_wtick

        function omp_get_default_device() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_default_device
        end function omp_get_default_device

        subroutine omp_set_default_device(dflt_device) bind(c)
          import
          integer (kind=omp_integer_kind), value :: dflt_device
        end subroutine omp_set_default_device

        function omp_get_num_devices() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_num_devices
        end function omp_get_num_devices

        function omp_get_num_teams() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_num_teams
        end function omp_get_num_teams

        function omp_get_team_num() bind(c)
          import
          integer (kind=omp_integer_kind) omp_get_team_num
        end function omp_get_team_num

        function omp_is_initial_device() bind(c)
          import
          logical (kind=omp_logical_kind) omp_is_initial_device
        end function omp_is_initial_device

        subroutine omp_init_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_init_lock
!DIR$ ENDIF
          import
          integer (kind=omp_lock_kind) lockvar
        end subroutine omp_init_lock

        subroutine omp_destroy_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_destroy_lock
!DIR$ ENDIF
          import
          integer (kind=omp_lock_kind) lockvar
        end subroutine omp_destroy_lock

        subroutine omp_set_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_set_lock
!DIR$ ENDIF
          import
          integer (kind=omp_lock_kind) lockvar
        end subroutine omp_set_lock

        subroutine omp_unset_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_unset_lock
!DIR$ ENDIF
          import
          integer (kind=omp_lock_kind) lockvar
        end subroutine omp_unset_lock

        function omp_test_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_test_lock
!DIR$ ENDIF
          import
          logical (kind=omp_logical_kind) omp_test_lock
          integer (kind=omp_lock_kind) lockvar
        end function omp_test_lock

        subroutine omp_init_nest_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_init_nest_lock
!DIR$ ENDIF
          import
          integer (kind=omp_nest_lock_kind) lockvar
        end subroutine omp_init_nest_lock

        subroutine omp_destroy_nest_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_destroy_nest_lock
!DIR$ ENDIF
          import
          integer (kind=omp_nest_lock_kind) lockvar
        end subroutine omp_destroy_nest_lock

        subroutine omp_set_nest_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_set_nest_lock
!DIR$ ENDIF
          import
          integer (kind=omp_nest_lock_kind) lockvar
        end subroutine omp_set_nest_lock

        subroutine omp_unset_nest_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_unset_nest_lock
!DIR$ ENDIF
          import
          integer (kind=omp_nest_lock_kind) lockvar
        end subroutine omp_unset_nest_lock

        function omp_test_nest_lock(lockvar) bind(c)
!DIR$ IF(__INTEL_COMPILER.GE.1400)
!DIR$ attributes known_intrinsic :: omp_test_nest_lock
!DIR$ ENDIF
          import
          integer (kind=omp_integer_kind) omp_test_nest_lock
          integer (kind=omp_nest_lock_kind) lockvar
        end function omp_test_nest_lock

!       ***
!       *** kmp_* entry points
!       ***

        subroutine kmp_set_stacksize(size) bind(c)
          import
          integer (kind=omp_integer_kind), value :: size
        end subroutine kmp_set_stacksize

        subroutine kmp_set_stacksize_s(size) bind(c)
          import
          integer (kind=kmp_size_t_kind), value :: size
        end subroutine kmp_set_stacksize_s

        subroutine kmp_set_blocktime(msec) bind(c)
          import
          integer (kind=omp_integer_kind), value :: msec
        end subroutine kmp_set_blocktime

        subroutine kmp_set_library_serial() bind(c)
        end subroutine kmp_set_library_serial

        subroutine kmp_set_library_turnaround() bind(c)
        end subroutine kmp_set_library_turnaround

        subroutine kmp_set_library_throughput() bind(c)
        end subroutine kmp_set_library_throughput

        subroutine kmp_set_library(libnum) bind(c)
          import
          integer (kind=omp_integer_kind), value :: libnum
        end subroutine kmp_set_library

        subroutine kmp_set_defaults(string) bind(c)
          character string(*)
        end subroutine kmp_set_defaults

        function kmp_get_stacksize() bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_stacksize
        end function kmp_get_stacksize

        function kmp_get_stacksize_s() bind(c)
          import
          integer (kind=kmp_size_t_kind) kmp_get_stacksize_s
        end function kmp_get_stacksize_s

        function kmp_get_blocktime() bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_blocktime
        end function kmp_get_blocktime

        function kmp_get_library() bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_library
        end function kmp_get_library

        function kmp_set_affinity(mask) bind(c)
          import
          integer (kind=omp_integer_kind) kmp_set_affinity
          integer (kind=kmp_affinity_mask_kind) mask
        end function kmp_set_affinity

        function kmp_get_affinity(mask) bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_affinity
          integer (kind=kmp_affinity_mask_kind) mask
        end function kmp_get_affinity

        function kmp_get_affinity_max_proc() bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_affinity_max_proc
        end function kmp_get_affinity_max_proc

        subroutine kmp_create_affinity_mask(mask) bind(c)
          import
          integer (kind=kmp_affinity_mask_kind) mask
        end subroutine kmp_create_affinity_mask

        subroutine kmp_destroy_affinity_mask(mask) bind(c)
          import
          integer (kind=kmp_affinity_mask_kind) mask
        end subroutine kmp_destroy_affinity_mask

        function kmp_set_affinity_mask_proc(proc, mask) bind(c)
          import
          integer (kind=omp_integer_kind) kmp_set_affinity_mask_proc
          integer (kind=omp_integer_kind), value :: proc
          integer (kind=kmp_affinity_mask_kind) mask
        end function kmp_set_affinity_mask_proc

        function kmp_unset_affinity_mask_proc(proc, mask) bind(c)
          import
          integer (kind=omp_integer_kind) kmp_unset_affinity_mask_proc
          integer (kind=omp_integer_kind), value :: proc
          integer (kind=kmp_affinity_mask_kind) mask
        end function kmp_unset_affinity_mask_proc

        function kmp_get_affinity_mask_proc(proc, mask) bind(c)
          import
          integer (kind=omp_integer_kind) kmp_get_affinity_mask_proc
          integer (kind=omp_integer_kind), value :: proc
          integer (kind=kmp_affinity_mask_kind) mask
        end function kmp_get_affinity_mask_proc

        function kmp_malloc(size) bind(c)
          import
          integer (kind=kmp_pointer_kind) kmp_malloc
          integer (kind=kmp_size_t_kind), value :: size
        end function kmp_malloc

        function kmp_calloc(nelem, elsize) bind(c)
          import
          integer (kind=kmp_pointer_kind) kmp_calloc
          integer (kind=kmp_size_t_kind), value :: nelem
          integer (kind=kmp_size_t_kind), value :: elsize
        end function kmp_calloc

        function kmp_realloc(ptr, size) bind(c)
          import
          integer (kind=kmp_pointer_kind) kmp_realloc
          integer (kind=kmp_pointer_kind), value :: ptr
          integer (kind=kmp_size_t_kind), value :: size
        end function kmp_realloc

        subroutine kmp_free(ptr) bind(c)
          import
          integer (kind=kmp_pointer_kind), value :: ptr
        end subroutine kmp_free

        subroutine kmp_set_warnings_on() bind(c)
        end subroutine kmp_set_warnings_on

        subroutine kmp_set_warnings_off() bind(c)
        end subroutine kmp_set_warnings_off

        subroutine kmp_init_lock_hinted(lockvar, lockhint) bind(c)
          import
          integer (kind=omp_lock_kind) lockvar
          integer (kind=kmp_lock_hint_kind), value :: lockhint
        end subroutine kmp_init_lock_hinted

        subroutine kmp_init_nest_lock_hinted(lockvar, lockhint) bind(c)
          import
          integer (kind=omp_lock_kind) lockvar
          integer (kind=kmp_lock_hint_kind), value :: lockhint
        end subroutine kmp_init_nest_lock_hinted

      end interface

!DIR$ IF DEFINED (__INTEL_OFFLOAD)
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_num_threads
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_dynamic
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_nested
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_num_threads
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_max_threads
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_thread_num
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_num_procs
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_in_parallel
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_in_final
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_dynamic
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_nested
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_thread_limit
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_max_active_levels
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_max_active_levels
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_level
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_active_level
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_ancestor_thread_num
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_team_size
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_schedule
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_schedule
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_proc_bind
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_wtime
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_wtick
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_default_device
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_default_device
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_is_initial_device
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_num_devices
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_num_teams
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_get_team_num
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_init_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_destroy_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_unset_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_test_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_init_nest_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_destroy_nest_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_set_nest_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_unset_nest_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: omp_test_nest_lock
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_stacksize
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_stacksize_s
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_blocktime
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_library_serial
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_library_turnaround
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_library_throughput
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_library
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_defaults
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_stacksize
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_stacksize_s
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_blocktime
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_library
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_affinity
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_affinity
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_affinity_max_proc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_create_affinity_mask
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_destroy_affinity_mask
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_affinity_mask_proc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_unset_affinity_mask_proc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_get_affinity_mask_proc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_malloc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_calloc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_realloc
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_free
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_warnings_on
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_set_warnings_off
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_init_lock_hinted
!DIR$ ATTRIBUTES OFFLOAD:MIC :: kmp_init_nest_lock_hinted

!DIR$ IF(__INTEL_COMPILER.GE.1400)
!$omp declare target(omp_set_num_threads )
!$omp declare target(omp_set_dynamic )
!$omp declare target(omp_set_nested )
!$omp declare target(omp_get_num_threads )
!$omp declare target(omp_get_max_threads )
!$omp declare target(omp_get_thread_num )
!$omp declare target(omp_get_num_procs )
!$omp declare target(omp_in_parallel )
!$omp declare target(omp_in_final )
!$omp declare target(omp_get_dynamic )
!$omp declare target(omp_get_nested )
!$omp declare target(omp_get_thread_limit )
!$omp declare target(omp_set_max_active_levels )
!$omp declare target(omp_get_max_active_levels )
!$omp declare target(omp_get_level )
!$omp declare target(omp_get_active_level )
!$omp declare target(omp_get_ancestor_thread_num )
!$omp declare target(omp_get_team_size )
!$omp declare target(omp_set_schedule )
!$omp declare target(omp_get_schedule )
!$omp declare target(omp_get_proc_bind )
!$omp declare target(omp_get_wtime )
!$omp declare target(omp_get_wtick )
!$omp declare target(omp_get_default_device )
!$omp declare target(omp_set_default_device )
!$omp declare target(omp_is_initial_device )
!$omp declare target(omp_get_num_devices )
!$omp declare target(omp_get_num_teams )
!$omp declare target(omp_get_team_num )
!$omp declare target(omp_init_lock )
!$omp declare target(omp_destroy_lock )
!$omp declare target(omp_set_lock )
!$omp declare target(omp_unset_lock )
!$omp declare target(omp_test_lock )
!$omp declare target(omp_init_nest_lock )
!$omp declare target(omp_destroy_nest_lock )
!$omp declare target(omp_set_nest_lock )
!$omp declare target(omp_unset_nest_lock )
!$omp declare target(omp_test_nest_lock )
!$omp declare target(kmp_set_stacksize )
!$omp declare target(kmp_set_stacksize_s )
!$omp declare target(kmp_set_blocktime )
!$omp declare target(kmp_set_library_serial )
!$omp declare target(kmp_set_library_turnaround )
!$omp declare target(kmp_set_library_throughput )
!$omp declare target(kmp_set_library )
!$omp declare target(kmp_set_defaults )
!$omp declare target(kmp_get_stacksize )
!$omp declare target(kmp_get_stacksize_s )
!$omp declare target(kmp_get_blocktime )
!$omp declare target(kmp_get_library )
!$omp declare target(kmp_set_affinity )
!$omp declare target(kmp_get_affinity )
!$omp declare target(kmp_get_affinity_max_proc )
!$omp declare target(kmp_create_affinity_mask )
!$omp declare target(kmp_destroy_affinity_mask )
!$omp declare target(kmp_set_affinity_mask_proc )
!$omp declare target(kmp_unset_affinity_mask_proc )
!$omp declare target(kmp_get_affinity_mask_proc )
!$omp declare target(kmp_malloc )
!$omp declare target(kmp_calloc )
!$omp declare target(kmp_realloc )
!$omp declare target(kmp_free )
!$omp declare target(kmp_set_warnings_on )
!$omp declare target(kmp_set_warnings_off )
!$omp declare target(kmp_init_lock_hinted )
!$omp declare target(kmp_init_nest_lock_hinted )
!DIR$ ENDIF
!DIR$ ENDIF

