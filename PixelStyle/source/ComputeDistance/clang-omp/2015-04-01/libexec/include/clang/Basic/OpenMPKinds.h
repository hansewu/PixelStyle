//===--- OpenMPKinds.h - OpenMP enums ---------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// \file
/// \brief Defines some OpenMP-specific enums and functions.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_BASIC_OPENMPKINDS_H
#define LLVM_CLANG_BASIC_OPENMPKINDS_H

#include "llvm/ADT/StringRef.h"

namespace clang {

/// \brief OpenMP directives.
enum OpenMPDirectiveKind {
  OMPD_unknown = 0,
#define OPENMP_DIRECTIVE(Name) \
  OMPD_##Name,
#define OPENMP_DIRECTIVE_EXT(Name, Str) \
  OMPD_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_DIRECTIVES
};

/// \brief OpenMP clauses.
enum OpenMPClauseKind {
  OMPC_unknown = 0,
#define OPENMP_CLAUSE(Name, Class) \
  OMPC_##Name,
#include "clang/Basic/OpenMPKinds.def"
  OMPC_threadprivate,
  NUM_OPENMP_CLAUSES
};

/// \brief OpenMP attributes for 'default' clause.
enum OpenMPDefaultClauseKind {
  OMPC_DEFAULT_unknown = 0,
#define OPENMP_DEFAULT_KIND(Name) \
  OMPC_DEFAULT_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_DEFAULT_KINDS
};

/// \brief OpenMP attributes for 'proc_bind' clause.
enum OpenMPProcBindClauseKind {
  OMPC_PROC_BIND_unknown = 0,
#define OPENMP_PROC_BIND_KIND(Name) \
  OMPC_PROC_BIND_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_PROC_BIND_KINDS
};

/// \brief OpenMP operators for 'reduction' clause.
enum OpenMPReductionClauseOperator {
  OMPC_REDUCTION_unknown = 0,
#define OPENMP_REDUCTION_OPERATOR(Name, Symbol) \
  OMPC_REDUCTION_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_REDUCTION_OPERATORS
};

/// \brief OpenMP dependence types for 'depend' clause.
enum OpenMPDependClauseType {
  OMPC_DEPEND_unknown = 0,
#define OPENMP_DEPENDENCE_TYPE(Name, Type) \
  OMPC_DEPEND_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_DEPENDENCE_TYPE
};

/// \brief OpenMP mapping kind for 'map' clause.
enum OpenMPMapClauseKind {
  OMPC_MAP_unknown = 0,
#define OPENMP_MAP_KIND(Name, Kind) \
  OMPC_MAP_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_MAP_KIND
};

/// \brief OpenMP attributes for 'schedule' clause.
enum OpenMPScheduleClauseKind {
  OMPC_SCHEDULE_unknown = 0,
#define OPENMP_SCHEDULE_KIND(Name) \
  OMPC_SCHEDULE_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_SCHEDULE_KINDS
};

/// \brief OpenMP attributes for 'dist_schedule' clause.
enum OpenMPDistScheduleClauseKind {
  OMPC_DIST_SCHEDULE_unknown = 0,
#define OPENMP_DIST_SCHEDULE_KIND(Name) \
  OMPC_DIST_SCHEDULE_##Name,
#include "clang/Basic/OpenMPKinds.def"
  NUM_OPENMP_DIST_SCHEDULE_KINDS
};

OpenMPDirectiveKind getOpenMPDirectiveKind(llvm::StringRef Str);
const char *getOpenMPDirectiveName(OpenMPDirectiveKind Kind);

OpenMPClauseKind getOpenMPClauseKind(llvm::StringRef Str);
const char *getOpenMPClauseName(OpenMPClauseKind Kind);

unsigned getOpenMPSimpleClauseType(OpenMPClauseKind Kind, llvm::StringRef Str);
const char *getOpenMPSimpleClauseTypeName(OpenMPClauseKind Kind, unsigned Type);

bool isAllowedClauseForDirective(OpenMPDirectiveKind DKind,
                                 OpenMPClauseKind CKind);

}

#endif
