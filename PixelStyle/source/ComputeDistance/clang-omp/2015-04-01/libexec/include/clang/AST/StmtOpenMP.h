//===- StmtOpenMP.h - Classes for OpenMP directives and clauses -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// \brief This file defines OpenMP AST classes for executable directives and
/// clauses.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_AST_STMTOPENMP_H
#define LLVM_CLANG_AST_STMTOPENMP_H

#include "clang/Basic/SourceLocation.h"
#include "clang/Basic/OpenMPKinds.h"
#include "clang/AST/Stmt.h"
#include "clang/AST/Expr.h"
#include "clang/AST/OpenMPClause.h"

namespace clang {

//===----------------------------------------------------------------------===//
// AST classes for directives.
//===----------------------------------------------------------------------===//

/// \brief This is a basic class for representing single OpenMP executable
/// directive.
///
class OMPExecutableDirective : public Stmt {
  friend class ASTStmtReader;
  /// \brief Kind of the directive.
  OpenMPDirectiveKind Kind;
  /// \brief Starting location of the directive kind.
  SourceLocation StartLoc;
  /// \brief Ending location of the directive.
  SourceLocation EndLoc;
  /// \brief Number of clauses.
  unsigned NumClauses;
  /// \brief Pointer to the list of clauses.
  OMPClause **const Clauses;
  /// \brief Number of associated expressions and statements.
  unsigned NumStmts;
  /// \brief Has associated statement.
  bool AStmt;

protected:
  /// \brief Build instance of directive of class \a K.
  ///
  /// \param SC Statement class.
  /// \param K Kind of OpenMP directive.
  /// \param SL Starting location of the directive kind.
  /// \param EL Ending location of the directive.
  /// \param N Number of clauses.
  /// \param ClausesAndStmt A pointer to the buffer for clauses.
  ///
  OMPExecutableDirective(StmtClass SC, OpenMPDirectiveKind K,
                         SourceLocation StartLoc, SourceLocation EndLoc,
                         unsigned N, OMPClause **CL, bool AStmt,
                         unsigned NumStmts)
      : Stmt(SC), Kind(K), StartLoc(StartLoc), EndLoc(EndLoc), NumClauses(N),
        Clauses(CL), NumStmts(NumStmts), AStmt(AStmt) {}

  /// \brief Fetches the list of clauses associated with this directive.
  llvm::MutableArrayRef<OMPClause *> getClauses() {
    return llvm::MutableArrayRef<OMPClause *>(Clauses, NumClauses);
  }

  /// \brief Fetches the list of clauses associated with this directive.
  ArrayRef<OMPClause *> getClauses() const {
    return ArrayRef<OMPClause *>(Clauses, NumClauses);
  }

  /// \brief Sets the list of variables for this clause.
  ///
  /// \brief Clauses The list of clauses for the directive.
  ///
  void setClauses(ArrayRef<OMPClause *> CL);

  /// \brief Set the associated statement for the directive.
  ///
  /// /param S Associated statement.
  ///
  void setAssociatedStmt(Stmt *S) {
    assert(AStmt && "No associated stmt allowed.");
    *reinterpret_cast<Stmt **>(&Clauses[NumClauses]) = S;
  }

  OMPClause **getClausesStorage() const { return Clauses; }

public:
  /// \brief Return starting location of directive kind.
  SourceLocation getLocStart() const { return StartLoc; }
  /// \brief Return ending location of directive.
  SourceLocation getLocEnd() const { return EndLoc; }

  /// \brief Set starting location of directive kind.
  ///
  /// \brief Loc New starting location of directive.
  ///
  void setLocStart(SourceLocation Loc) { StartLoc = Loc; }
  /// \brief Set ending location of directive.
  ///
  /// \brief Loc New ending location of directive.
  ///
  void setLocEnd(SourceLocation Loc) { EndLoc = Loc; }

  /// \brief Get number of clauses.
  unsigned getNumClauses() const { return NumClauses; }

  /// \brief Fetches specified clause.
  ///
  /// \param i Number of clause.
  ///
  OMPClause *getClause(unsigned i) {
    assert(i < NumClauses && "Wrong number of clause!");
    return getClauses()[i];
  }

  /// \brief Fetches specified clause.
  ///
  /// \param i Number of clause.
  ///
  OMPClause *getClause(unsigned i) const {
    assert(i < NumClauses && "Wrong number of clause!");
    return getClauses()[i];
  }

  /// \brief Return statement associated with the directive.
  Stmt *getAssociatedStmt() {
    return AStmt ? *reinterpret_cast<Stmt **>(&Clauses[NumClauses]) : 0;
  }

  /// \brief Return statement associated with the directive.
  Stmt *getAssociatedStmt() const {
    return AStmt ? *reinterpret_cast<Stmt **>(&Clauses[NumClauses]) : 0;
  }

  bool hasAssociatedStmt() const { return AStmt; }

  OpenMPDirectiveKind getDirectiveKind() const { return Kind; }

  static bool classof(const Stmt *S) {
    return S->getStmtClass() >= firstOMPExecutableDirectiveConstant &&
           S->getStmtClass() <= lastOMPExecutableDirectiveConstant;
  }

  child_range children() {
    return child_range(reinterpret_cast<Stmt **>(&Clauses[NumClauses]),
                       reinterpret_cast<Stmt **>(&Clauses[NumClauses]) +
                           NumStmts);
  }

  ArrayRef<OMPClause *> clauses() { return getClauses(); }
  ArrayRef<OMPClause *> clauses() const { return getClauses(); }
};

/// \brief This represents '#pragma omp parallel' directive.
///
/// \code
/// #pragma omp parallel private(a,b) reduction(+: c,d)
/// \endcode
/// In this example directive '#pragma omp parallel' has clauses 'private'
/// with the variables 'a' and 'b' and 'reduction' with operator '+' and
/// variables 'c' and 'd'.
///
class OMPParallelDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPParallelDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                       unsigned N)
      : OMPExecutableDirective(
            OMPParallelDirectiveClass, OMPD_parallel, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPParallelDirective(unsigned N)
      : OMPExecutableDirective(
            OMPParallelDirectiveClass, OMPD_parallel, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPParallelDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPParallelDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                           EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPParallelDirectiveClass;
  }
};

/// \brief This represents '#pragma omp for' directive.
///
/// \code
/// #pragma omp for private(a,b) reduction(+: c,d) ordered
/// \endcode
/// In this example directive '#pragma omp for' has clauses 'private'
/// with the variables 'a' and 'b', 'reduction' with operator '+' and
/// variables 'c' and 'd' and 'ordered'.
///
class OMPForDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPForDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                  unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPForDirectiveClass, OMPD_for, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPForDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPForDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPForDirectiveClass, OMPD_for, SourceLocation(), SourceLocation(),
            N, reinterpret_cast<OMPClause **>(
                   reinterpret_cast<char *>(this) +
                   llvm::RoundUpToAlignment(sizeof(OMPForDirective),
                                            llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPForDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPForDirective *CreateEmpty(const ASTContext &C,
                                      unsigned CollapsedNum, unsigned N,
                                      EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPForDirectiveClass;
  }
};

/// \brief This represents '#pragma omp parallel for' directive.
///
/// \code
/// #pragma omp parallel for private(a,b) reduction(+: c,d) ordered
/// \endcode
/// In this example directive '#pragma omp parallel for' has clauses 'private'
/// with the variables 'a' and 'b', 'reduction' with operator '+' and
/// variables 'c' and 'd' and 'ordered'.
///
class OMPParallelForDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPParallelForDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                          unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPParallelForDirectiveClass, OMPD_parallel_for, StartLoc, EndLoc,
            N, reinterpret_cast<OMPClause **>(
                   reinterpret_cast<char *>(this) +
                   llvm::RoundUpToAlignment(sizeof(OMPParallelForDirective),
                                            llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPParallelForDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPParallelForDirectiveClass, OMPD_parallel_for, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelForDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPParallelForDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPParallelForDirective *CreateEmpty(const ASTContext &C,
                                              unsigned CollapsedNum, unsigned N,
                                              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPParallelForDirectiveClass;
  }
};

/// \brief This represents '#pragma omp simd' directive.
///
/// \code
/// #pragma omp simd private(a,b) linear(i,j:s) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp simd' has clauses 'private'
/// with the variables 'a' and 'b', 'linear' with variables 'i', 'j' and
/// linear step 's', 'reduction' with operator '+' and variables 'c' and 'd'.
///
class OMPSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPSimdDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                   unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPSimdDirectiveClass, OMPD_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPSimdDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPSimdDirectiveClass, OMPD_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPSimdDirective *CreateEmpty(const ASTContext &C,
                                       unsigned CollapsedNum, unsigned N,
                                       EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp for simd' directive.
///
/// \code
/// #pragma omp for simd private(a,b) linear(i,j:s) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp for simd' has clauses 'private'
/// with the variables 'a' and 'b', 'linear' with variables 'i', 'j' and
/// linear step 's', 'reduction' with operator '+' and variables 'c' and 'd'.
///
class OMPForSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPForSimdDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                      unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPForSimdDirectiveClass, OMPD_for_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPForSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPForSimdDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPForSimdDirectiveClass, OMPD_for_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPForSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPForSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPForSimdDirective *CreateEmpty(const ASTContext &C,
                                          unsigned CollapsedNum, unsigned N,
                                          EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPForSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp parallel for simd' directive.
///
/// \code
/// #pragma omp parallel for simd private(a,b) linear(i,j:s) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp parallel for simd' has clauses
/// 'private' with the variables 'a' and 'b', 'linear' with variables 'i', 'j'
/// and linear step 's', 'reduction' with operator '+' and variables 'c' and
/// 'd'.
///
class OMPParallelForSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPParallelForSimdDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                              unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPParallelForSimdDirectiveClass, OMPD_parallel_for_simd, StartLoc,
            EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelForSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPParallelForSimdDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPParallelForSimdDirectiveClass, OMPD_parallel_for_simd,
            SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelForSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPParallelForSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPParallelForSimdDirective *CreateEmpty(const ASTContext &C,
                                                  unsigned CollapsedNum,
                                                  unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPParallelForSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp distribute simd' directive.
///
/// \code
/// #pragma omp distribute simd private(a,b) linear(i,j:s) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp distribute simd' has clauses
/// 'private' with the variables 'a' and 'b', 'linear' with variables 'i', 'j'
/// and linear step 's', 'reduction' with operator '+' and variables 'c' and
/// 'd'.
///
class OMPDistributeSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPDistributeSimdDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                             unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeSimdDirectiveClass, OMPD_distribute_simd, StartLoc,
            EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPDistributeSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPDistributeSimdDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeSimdDirectiveClass, OMPD_distribute_simd,
            SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPDistributeSimdDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPDistributeSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPDistributeSimdDirective *CreateEmpty(const ASTContext &C,
                                                 unsigned CollapsedNum,
                                                 unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPDistributeSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp distribute parallel for' directive.
///
/// \code
/// #pragma omp distribute parallel for private(a,b) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp distribute parallel for' has clauses
/// 'private'
/// with the variables 'a' and 'b' and
/// 'reduction' with operator '+' and variables 'c' and 'd'.
///
class OMPDistributeParallelForDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPDistributeParallelForDirective(SourceLocation StartLoc,
                                    SourceLocation EndLoc,
                                    unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeParallelForDirectiveClass,
            OMPD_distribute_parallel_for, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPDistributeParallelForDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeParallelForDirectiveClass,
            OMPD_distribute_parallel_for, SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPDistributeParallelForDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPDistributeParallelForDirective *CreateEmpty(const ASTContext &C,
                                                        unsigned CollapsedNum,
                                                        unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPDistributeParallelForDirectiveClass;
  }
};

/// \brief This represents '#pragma omp distribute parallel for simd' directive.
///
/// \code
/// #pragma omp distribute parallel for simd private(a,b) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp distribute parallel for simd' has
/// clauses 'private' with the variables 'a' and 'b' and 'reduction' with
/// operator '+' and variables 'c' and 'd'.
///
class OMPDistributeParallelForSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPDistributeParallelForSimdDirective(SourceLocation StartLoc,
                                        SourceLocation EndLoc,
                                        unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeParallelForSimdDirectiveClass,
            OMPD_distribute_parallel_for_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPDistributeParallelForSimdDirective(unsigned CollapsedNum,
                                                 unsigned N)
      : OMPExecutableDirective(
            OMPDistributeParallelForSimdDirectiveClass,
            OMPD_distribute_parallel_for_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPDistributeParallelForSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPDistributeParallelForSimdDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPDistributeParallelForSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp teams distribute parallel for'
/// directive.
///
/// \code
/// #pragma omp teams distribute parallel for private(a,b) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp teams distribute parallel for' has
/// clauses 'private' with the variables 'a' and 'b' and 'reduction' with
/// operator '+' and variables 'c' and 'd'.
///
class OMPTeamsDistributeParallelForDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTeamsDistributeParallelForDirective(SourceLocation StartLoc,
                                         SourceLocation EndLoc,
                                         unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeParallelForDirectiveClass,
            OMPD_teams_distribute_parallel_for, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTeamsDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTeamsDistributeParallelForDirective(unsigned CollapsedNum,
                                                  unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeParallelForDirectiveClass,
            OMPD_teams_distribute_parallel_for, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTeamsDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTeamsDistributeParallelForDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTeamsDistributeParallelForDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTeamsDistributeParallelForDirectiveClass;
  }
};

/// \brief This represents '#pragma omp teams distribute parallel for simd'
/// directive.
///
/// \code
/// #pragma omp teams distribute parallel for simd private(a,b) reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp teams distribute parallel for simd'
/// has clauses 'private' with the variables 'a' and 'b' and 'reduction' with
/// operator '+' and variables 'c' and 'd'.
///
class OMPTeamsDistributeParallelForSimdDirective
    : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTeamsDistributeParallelForSimdDirective(SourceLocation StartLoc,
                                             SourceLocation EndLoc,
                                             unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeParallelForSimdDirectiveClass,
            OMPD_teams_distribute_parallel_for_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTeamsDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTeamsDistributeParallelForSimdDirective(unsigned CollapsedNum,
                                                      unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeParallelForSimdDirectiveClass,
            OMPD_teams_distribute_parallel_for_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTeamsDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTeamsDistributeParallelForSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTeamsDistributeParallelForSimdDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTeamsDistributeParallelForSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target teams distribute parallel for'
/// directive.
///
/// \code
/// #pragma omp target teams distribute parallel for private(a,b)
/// reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp target teams distribute parallel for'
/// has clauses 'private' with the variables 'a' and 'b' and 'reduction' with
/// operator '+' and variables 'c' and 'd'.
///
class OMPTargetTeamsDistributeParallelForDirective
    : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetTeamsDistributeParallelForDirective(SourceLocation StartLoc,
                                               SourceLocation EndLoc,
                                               unsigned CollapsedNum,
                                               unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeParallelForDirectiveClass,
            OMPD_target_teams_distribute_parallel_for, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetTeamsDistributeParallelForDirective(unsigned CollapsedNum,
                                                        unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeParallelForDirectiveClass,
            OMPD_target_teams_distribute_parallel_for, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeParallelForDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetTeamsDistributeParallelForDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetTeamsDistributeParallelForDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() ==
           OMPTargetTeamsDistributeParallelForDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target teams distribute parallel for
/// simd' directive.
///
/// \code
/// #pragma omp target teams distribute parallel for simd private(a,b)
/// reduction(+:c,d)
/// \endcode
/// In this example directive '#pragma omp target teams distribute parallel for
/// simd' has clauses 'private' with the variables 'a' and 'b' and 'reduction'
/// with operator '+' and variables 'c' and 'd'.
///
class OMPTargetTeamsDistributeParallelForSimdDirective
    : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetTeamsDistributeParallelForSimdDirective(SourceLocation StartLoc,
                                                   SourceLocation EndLoc,
                                                   unsigned CollapsedNum,
                                                   unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeParallelForSimdDirectiveClass,
            OMPD_target_teams_distribute_parallel_for_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetTeamsDistributeParallelForSimdDirective(
      unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeParallelForSimdDirectiveClass,
            OMPD_target_teams_distribute_parallel_for_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeParallelForSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 7 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setLowerBound(Expr *LB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5] = LB;
  }
  void setUpperBound(Expr *UB) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6] = UB;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[7]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetTeamsDistributeParallelForSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, Expr *LowerBound,
         Expr *UpperBound, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetTeamsDistributeParallelForSimdDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[4]);
  }
  Expr *getLowerBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[5]);
  }
  Expr *getUpperBound() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[6]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &reinterpret_cast<OMPClause *const *>(this +
                                                  1)[getNumClauses()])[7])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }
  Expr *getLowerBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]);
  }
  Expr *getUpperBound() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[6]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() ==
           OMPTargetTeamsDistributeParallelForSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp sections' directive.
///
/// \code
/// #pragma omp sections private(a,b) reduction(+: c,d) nowait
/// \endcode
/// In this example directive '#pragma omp sections' has clauses 'private'
/// with the variables 'a' and 'b', 'reduction' with operator '+' and
/// variables 'c' and 'd' and 'nowait'.
///
class OMPSectionsDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPSectionsDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                       unsigned N)
      : OMPExecutableDirective(
            OMPSectionsDirectiveClass, OMPD_sections, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSectionsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPSectionsDirective(unsigned N)
      : OMPExecutableDirective(
            OMPSectionsDirectiveClass, OMPD_sections, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSectionsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPSectionsDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPSectionsDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                           EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPSectionsDirectiveClass;
  }
};

/// \brief This represents '#pragma omp parallel sections' directive.
///
/// \code
/// #pragma omp parallel sections private(a,b) reduction(+: c,d)
/// \endcode
/// In this example directive '#pragma omp parallel sections' has clauses
/// 'private'
/// with the variables 'a' and 'b', 'reduction' with operator '+' and
/// variables 'c' and 'd'.
///
class OMPParallelSectionsDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPParallelSectionsDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                               unsigned N)
      : OMPExecutableDirective(
            OMPParallelSectionsDirectiveClass, OMPD_parallel_sections, StartLoc,
            EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelSectionsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPParallelSectionsDirective(unsigned N)
      : OMPExecutableDirective(
            OMPParallelSectionsDirectiveClass, OMPD_parallel_sections,
            SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPParallelSectionsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPParallelSectionsDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPParallelSectionsDirective *CreateEmpty(const ASTContext &C,
                                                   unsigned N, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPParallelSectionsDirectiveClass;
  }
};

/// \brief This represents '#pragma omp section' directive.
///
/// \code
/// #pragma omp section
/// \endcode
/// In this example directive '#pragma omp section' is used.
///
class OMPSectionDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPSectionDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(
            OMPSectionDirectiveClass, OMPD_section, StartLoc, EndLoc, 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSectionDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPSectionDirective()
      : OMPExecutableDirective(
            OMPSectionDirectiveClass, OMPD_section, SourceLocation(),
            SourceLocation(), 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSectionDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPSectionDirective *Create(const ASTContext &C,
                                     SourceLocation StartLoc,
                                     SourceLocation EndLoc,
                                     Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  ///
  static OMPSectionDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPSectionDirectiveClass;
  }
};

/// \brief This represents '#pragma omp single' directive.
///
/// \code
/// #pragma omp single private(a,b) copyprivate(c,d)
/// \endcode
/// In this example directive '#pragma omp single' has clauses 'private'
/// with the variables 'a' and 'b', 'copyprivate' with variables 'c' and 'd'.
///
class OMPSingleDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPSingleDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPSingleDirectiveClass, OMPD_single, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSingleDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPSingleDirective(unsigned N)
      : OMPExecutableDirective(
            OMPSingleDirectiveClass, OMPD_single, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPSingleDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPSingleDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPSingleDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                         EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPSingleDirectiveClass;
  }
};

/// \brief This represents '#pragma omp task' directive.
///
/// \code
/// #pragma omp task private(a,b) firstprivate(c,d)
/// \endcode
/// In this example directive '#pragma omp task' has clauses 'private'
/// with the variables 'a' and 'b', 'firstprivate' with variables 'c' and 'd'.
///
class OMPTaskDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTaskDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPTaskDirectiveClass, OMPD_task, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTaskDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTaskDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTaskDirectiveClass, OMPD_task, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTaskDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTaskDirective *Create(const ASTContext &C, SourceLocation StartLoc,
                                  SourceLocation EndLoc,
                                  ArrayRef<OMPClause *> Clauses,
                                  Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTaskDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                       EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTaskDirectiveClass;
  }
};

/// \brief This represents '#pragma omp taskyield' directive.
///
/// \code
/// #pragma omp taskyield
/// \endcode
/// In this example directive '#pragma omp taskyield' is used.
///
class OMPTaskyieldDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPTaskyieldDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(OMPTaskyieldDirectiveClass, OMPD_taskyield,
                               StartLoc, EndLoc, 0, 0, false, 0) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPTaskyieldDirective()
      : OMPExecutableDirective(OMPTaskyieldDirectiveClass, OMPD_taskyield,
                               SourceLocation(), SourceLocation(), 0, 0, false,
                               0) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  static OMPTaskyieldDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPTaskyieldDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTaskyieldDirectiveClass;
  }
};

/// \brief This represents '#pragma omp master' directive.
///
/// \code
/// #pragma omp master
/// \endcode
/// In this example directive '#pragma omp master' is used.
///
class OMPMasterDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPMasterDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(
            OMPMasterDirectiveClass, OMPD_master, StartLoc, EndLoc, 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPMasterDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPMasterDirective()
      : OMPExecutableDirective(
            OMPMasterDirectiveClass, OMPD_master, SourceLocation(),
            SourceLocation(), 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPMasterDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPMasterDirective *Create(const ASTContext &C,
                                    SourceLocation StartLoc,
                                    SourceLocation EndLoc,
                                    Stmt *AssociatedStmt);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPMasterDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPMasterDirectiveClass;
  }
};

/// \brief This represents '#pragma omp critical' directive.
///
/// \code
/// #pragma omp critical
/// \endcode
/// In this example directive '#pragma omp critical' is used.
///
class OMPCriticalDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  /// \brief Name of thee directive.
  DeclarationNameInfo DirName;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPCriticalDirective(DeclarationNameInfo Name, SourceLocation StartLoc,
                       SourceLocation EndLoc)
      : OMPExecutableDirective(
            OMPCriticalDirectiveClass, OMPD_critical, StartLoc, EndLoc, 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPCriticalDirective),
                                         sizeof(Stmt *))),
            true, 1),
        DirName(Name) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPCriticalDirective()
      : OMPExecutableDirective(
            OMPCriticalDirectiveClass, OMPD_critical, SourceLocation(),
            SourceLocation(), 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPCriticalDirective),
                                         sizeof(Stmt *))),
            true, 1),
        DirName() {}
  /// \brief Set name of the directive.
  ///
  /// \param Name Name of the directive.
  ///
  void setDirectiveName(const DeclarationNameInfo &Name) { DirName = Name; }

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPCriticalDirective *
  Create(const ASTContext &C, DeclarationNameInfo DirName,
         SourceLocation StartLoc, SourceLocation EndLoc, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPCriticalDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  /// \brief Return name of the directive.
  ///
  DeclarationNameInfo getDirectiveName() const { return DirName; }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPCriticalDirectiveClass;
  }
};

/// \brief This represents '#pragma omp barrier' directive.
///
/// \code
/// #pragma omp barrier
/// \endcode
/// In this example directive '#pragma omp barrier' is used.
///
class OMPBarrierDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPBarrierDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(OMPBarrierDirectiveClass, OMPD_barrier, StartLoc,
                               EndLoc, 0, 0, false, 0) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPBarrierDirective()
      : OMPExecutableDirective(OMPBarrierDirectiveClass, OMPD_barrier,
                               SourceLocation(), SourceLocation(), 0, 0, false,
                               0) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  static OMPBarrierDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPBarrierDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPBarrierDirectiveClass;
  }
};

/// \brief This represents '#pragma omp taskwait' directive.
///
/// \code
/// #pragma omp taskwait
/// \endcode
/// In this example directive '#pragma omp taskwait' is used.
///
class OMPTaskwaitDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPTaskwaitDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(OMPTaskwaitDirectiveClass, OMPD_taskwait,
                               StartLoc, EndLoc, 0, 0, false, 0) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPTaskwaitDirective()
      : OMPExecutableDirective(OMPTaskwaitDirectiveClass, OMPD_taskwait,
                               SourceLocation(), SourceLocation(), 0, 0, false,
                               0) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  static OMPTaskwaitDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPTaskwaitDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTaskwaitDirectiveClass;
  }
};

/// \brief This represents '#pragma omp taskgroup' directive.
///
/// \code
/// #pragma omp taskgroup
/// \endcode
/// In this example directive '#pragma omp taskgroup' is used.
///
class OMPTaskgroupDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPTaskgroupDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(
            OMPTaskgroupDirectiveClass, OMPD_taskgroup, StartLoc, EndLoc, 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTaskgroupDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPTaskgroupDirective()
      : OMPExecutableDirective(
            OMPTaskgroupDirectiveClass, OMPD_taskgroup, SourceLocation(),
            SourceLocation(), 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTaskgroupDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTaskgroupDirective *Create(const ASTContext &C,
                                       SourceLocation StartLoc,
                                       SourceLocation EndLoc,
                                       Stmt *AssociatedStmt);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPTaskgroupDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTaskgroupDirectiveClass;
  }
};

/// \brief This represents '#pragma omp atomic' directive.
///
/// \code
/// #pragma omp atomic capture seq_cst
/// \endcode
/// In this example directive '#pragma omp atomic' has clauses 'capture' and
/// 'seq_cst'.
///
class OMPAtomicDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  /// \brief Binary operator for atomic.
  BinaryOperatorKind BinOp;
  /// \brief Capture kind - true, if after expr, false, if before.
  bool CaptureAfter;
  /// \brief true, if operator for 'x' is reversed, false - otherwise.
  bool Reversed;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPAtomicDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPAtomicDirectiveClass, OMPD_atomic, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPAtomicDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 4),
        BinOp(BO_Assign), CaptureAfter(false), Reversed(false) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPAtomicDirective(unsigned N)
      : OMPExecutableDirective(
            OMPAtomicDirectiveClass, OMPD_atomic, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPAtomicDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 4),
        BinOp(BO_Assign), CaptureAfter(false), Reversed(false) {}

  /// \brief Sets binary operator for atomic.
  void setOperator(BinaryOperatorKind Op) { BinOp = Op; }

  /// \brief Sets 'v' parameter for atomic.
  void setV(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }

  /// \brief Sets 'x' parameter for atomic.
  void setX(Expr *X) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = X;
  }

  /// \brief Sets 'expr' parameter for atomic.
  void setExpr(Expr *OpExpr) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] =
        OpExpr;
  }

  /// \brief Sets capture kind parameter for atomic.
  void setCaptureAfter(bool CaptureKind) { CaptureAfter = CaptureKind; }

  /// \brief Sets update rules for 'x' parameter for atomic.
  void setReversed(bool IsReversed) { Reversed = IsReversed; }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPAtomicDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *V, Expr *X,
         Expr *OpExpr, BinaryOperatorKind Op, bool CaptureAfter, bool Reversed);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPAtomicDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                         EmptyShell);

  /// \brief Returns binary operator for atomic.
  BinaryOperatorKind getOperator() const { return BinOp; }

  /// \brief Returns 'v' parameter for atomic.
  Expr *getV() const {
    return reinterpret_cast<Expr *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[1];
  }

  /// \brief Returns 'x' parameter for atomic.
  Expr *getX() const {
    return reinterpret_cast<Expr *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[2];
  }

  /// \brief Returns 'expr' parameter for atomic.
  Expr *getExpr() const {
    return reinterpret_cast<Expr *const *>(
        &reinterpret_cast<OMPClause *const *>(this + 1)[getNumClauses()])[3];
  }

  /// \brief Returns capture kind parameter for atomic.
  bool isCaptureAfter() const { return CaptureAfter; }

  /// \brief Returns update kind of 'x' parameter for atomic.
  bool isReversed() const { return Reversed; }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPAtomicDirectiveClass;
  }
};

/// \brief This represents '#pragma omp flush' directive.
///
/// \code
/// #pragma omp flush(a,b)
/// \endcode
/// In this example directive '#pragma omp flush' has list of variables 'a' and
/// 'b'.
///
class OMPFlushDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPFlushDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPFlushDirectiveClass, OMPD_flush, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPFlushDirective),
                                         llvm::alignOf<OMPClause *>())),
            false, 0) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPFlushDirective(unsigned N)
      : OMPExecutableDirective(
            OMPFlushDirectiveClass, OMPD_flush, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPFlushDirective),
                                         llvm::alignOf<OMPClause *>())),
            false, 0) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  ///
  static OMPFlushDirective *Create(const ASTContext &C, SourceLocation StartLoc,
                                   SourceLocation EndLoc,
                                   ArrayRef<OMPClause *> Clauses);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPFlushDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                        EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPFlushDirectiveClass;
  }
};

/// \brief This represents '#pragma omp ordered' directive.
///
/// \code
/// #pragma omp ordered
/// \endcode
/// In this example directive '#pragma omp ordered' is used.
///
class OMPOrderedDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  ///
  OMPOrderedDirective(SourceLocation StartLoc, SourceLocation EndLoc)
      : OMPExecutableDirective(
            OMPOrderedDirectiveClass, OMPD_ordered, StartLoc, EndLoc, 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPOrderedDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  explicit OMPOrderedDirective()
      : OMPExecutableDirective(
            OMPOrderedDirectiveClass, OMPD_ordered, SourceLocation(),
            SourceLocation(), 0,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPOrderedDirective),
                                         sizeof(Stmt *))),
            true, 1) {}

public:
  /// \brief Creates directive.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPOrderedDirective *Create(const ASTContext &C,
                                     SourceLocation StartLoc,
                                     SourceLocation EndLoc,
                                     Stmt *AssociatedStmt);

  /// \brief Creates an empty directive.
  ///
  /// \param C AST context.
  ///
  static OMPOrderedDirective *CreateEmpty(const ASTContext &C, EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPOrderedDirectiveClass;
  }
};

/// \brief This represents '#pragma omp teams' directive.
///
/// \code
/// #pragma omp teams private(a,b) reduction(+: c,d)
/// \endcode
/// In this example directive '#pragma omp teams' has clauses 'private'
/// with the variables 'a' and 'b' and 'reduction' with operator '+' and
/// variables 'c' and 'd'.
///
class OMPTeamsDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTeamsDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDirectiveClass, OMPD_teams, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTeamsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTeamsDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDirectiveClass, OMPD_teams, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTeamsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTeamsDirective *Create(const ASTContext &C, SourceLocation StartLoc,
                                   SourceLocation EndLoc,
                                   ArrayRef<OMPClause *> Clauses,
                                   Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTeamsDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                        EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTeamsDirectiveClass;
  }
};

/// \brief This represents '#pragma omp distribute' directive.
///
/// \code
/// #pragma omp distribute private(a,b) collapse(2)
/// \endcode
/// In this example directive '#pragma omp distribute' has clauses 'private'
/// with the variables 'a' and 'b', and 'collapse' with number '2' of loops to
/// be collapsed.
///
class OMPDistributeDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPDistributeDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                         unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeDirectiveClass, OMPD_distribute, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPDistributeDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPDistributeDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPDistributeDirectiveClass, OMPD_distribute, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPDistributeDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPDistributeDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPDistributeDirective *CreateEmpty(const ASTContext &C,
                                             unsigned CollapsedNum, unsigned N,
                                             EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(&(reinterpret_cast<Stmt *const *>(
            &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPDistributeDirectiveClass;
  }
};

/// \brief This represents '#pragma omp cancel' directive.
///
/// \code
/// #pragma omp cancel parallel
/// \endcode
/// In this example directive '#pragma omp cancel' has construct type
/// 'parallel'.
///
class OMPCancelDirective : public OMPExecutableDirective {
  OpenMPDirectiveKind ConstructType;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  /// \param ConstructType Construct type.
  ///
  OMPCancelDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N,
                     OpenMPDirectiveKind ConstructType)
      : OMPExecutableDirective(
            OMPCancelDirectiveClass, OMPD_cancel, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPCancelDirective),
                                         llvm::alignOf<OMPClause *>())),
            false, 0),
        ConstructType(ConstructType) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  /// \param ConstructType Construct type.
  ///
  explicit OMPCancelDirective(unsigned N, OpenMPDirectiveKind ConstructType)
      : OMPExecutableDirective(
            OMPCancelDirectiveClass, OMPD_cancel, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPCancelDirective),
                                         llvm::alignOf<OMPClause *>())),
            false, 0),
        ConstructType(ConstructType) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param ConstructType Construct type.
  ///
  static OMPCancelDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, OpenMPDirectiveKind ConstructType);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  /// \param ConstructType Construct type.
  ///
  static OMPCancelDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                         OpenMPDirectiveKind ConstructType,
                                         EmptyShell);

  /// \brief Fetches construct type.
  OpenMPDirectiveKind getConstructType() const { return ConstructType; }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPCancelDirectiveClass;
  }
};

/// \brief This represents '#pragma omp cancellation point' directive.
///
/// \code
/// #pragma omp cancellation point parallel
/// \endcode
/// In this example directive '#pragma omp cancellation point' has construct
/// type 'parallel'.
///
class OMPCancellationPointDirective : public OMPExecutableDirective {
  OpenMPDirectiveKind ConstructType;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param ConstructType Construct type.
  ///
  OMPCancellationPointDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                                OpenMPDirectiveKind ConstructType)
      : OMPExecutableDirective(OMPCancellationPointDirectiveClass,
                               OMPD_cancellation_point, StartLoc, EndLoc, 0, 0,
                               false, 0),
        ConstructType(ConstructType) {}

  /// \brief Build an empty directive.
  ///
  /// \param ConstructType Construct type.
  ///
  explicit OMPCancellationPointDirective(OpenMPDirectiveKind ConstructType)
      : OMPExecutableDirective(OMPCancellationPointDirectiveClass,
                               OMPD_cancellation_point, SourceLocation(),
                               SourceLocation(), 0, 0, false, 0),
        ConstructType(ConstructType) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param ConstructType Construct type.
  ///
  static OMPCancellationPointDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         OpenMPDirectiveKind ConstructType);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param ConstructType Construct type.
  ///
  static OMPCancellationPointDirective *
  CreateEmpty(const ASTContext &C, OpenMPDirectiveKind ConstructType,
              EmptyShell);

  /// \brief Fetches construct type.
  OpenMPDirectiveKind getConstructType() const { return ConstructType; }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPCancellationPointDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target' directive.
///
/// \code
/// #pragma omp target device(0) if(a) map(b[:])
/// \endcode
/// In this example directive '#pragma omp target' has clauses 'device'
/// with the value '0', 'if' with condition 'a' and 'map' with array
/// section 'b[:]'.
///
class OMPTargetDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetDirective(SourceLocation StartLoc, SourceLocation EndLoc, unsigned N)
      : OMPExecutableDirective(
            OMPTargetDirectiveClass, OMPD_target, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTargetDirectiveClass, OMPD_target, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                         EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target teams' directive.
///
/// \code
/// #pragma omp target teams device(0) if(a) map(b[:]) num_teams(10)
/// \endcode
/// In this example directive '#pragma omp target teams' has clauses 'device'
/// with the value '0', 'if' with condition 'a', 'map' with array
/// section 'b[:]' and 'num_teams' with number of teams '10'.
///
class OMPTargetTeamsDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetTeamsDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                          unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDirectiveClass, OMPD_target_teams, StartLoc, EndLoc,
            N, reinterpret_cast<OMPClause **>(
                   reinterpret_cast<char *>(this) +
                   llvm::RoundUpToAlignment(sizeof(OMPTargetTeamsDirective),
                                            llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetTeamsDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDirectiveClass, OMPD_target_teams, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetTeamsDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetTeamsDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetTeamsDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                              EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetTeamsDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target data' directive.
///
/// \code
/// #pragma omp target data device(0) if(a) map(b[:])
/// \endcode
/// In this example directive '#pragma omp target data' has clauses 'device'
/// with the value '0', 'if' with condition 'a' and 'map' with array
/// section 'b[:]'.
///
class OMPTargetDataDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetDataDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                         unsigned N)
      : OMPExecutableDirective(
            OMPTargetDataDirectiveClass, OMPD_target_data, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetDataDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetDataDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTargetDataDirectiveClass, OMPD_target_data, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetDataDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 1) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetDataDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetDataDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                             EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetDataDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target update' directive.
///
/// \code
/// #pragma omp target update to(a) from(b) device(1)
/// \endcode
/// In this example directive '#pragma omp target update' has clause 'to' with
/// argument 'a', clause 'from' with argument 'b' and clause 'device' with
/// argument '1'.
///
class OMPTargetUpdateDirective : public OMPExecutableDirective {
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetUpdateDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                           unsigned N)
      : OMPExecutableDirective(
            OMPTargetUpdateDirectiveClass, OMPD_target_update, StartLoc, EndLoc,
            N, reinterpret_cast<OMPClause **>(
                   reinterpret_cast<char *>(this) +
                   llvm::RoundUpToAlignment(sizeof(OMPTargetUpdateDirective),
                                            llvm::alignOf<OMPClause *>())),
            false, 0) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetUpdateDirective(unsigned N)
      : OMPExecutableDirective(
            OMPTargetUpdateDirectiveClass, OMPD_target_update, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTargetUpdateDirective),
                                         llvm::alignOf<OMPClause *>())),
            false, 0) {}

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  ///
  static OMPTargetUpdateDirective *Create(const ASTContext &C,
                                          SourceLocation StartLoc,
                                          SourceLocation EndLoc,
                                          ArrayRef<OMPClause *> Clauses);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetUpdateDirective *CreateEmpty(const ASTContext &C, unsigned N,
                                               EmptyShell);

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetUpdateDirectiveClass;
  }
};

/// \brief This represents '#pragma omp teams distribute' directive.
///
/// \code
/// #pragma omp teams distribute private(a,b) collapse(2)
/// \endcode
/// In this example directive '#pragma omp teams distribute' has clauses
/// 'private' with the variables 'a' and 'b', and 'collapse' with number '2' of
/// loops to be collapsed.
///
class OMPTeamsDistributeDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTeamsDistributeDirective(SourceLocation StartLoc, SourceLocation EndLoc,
                              unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeDirectiveClass, OMPD_teams_distribute, StartLoc,
            EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTeamsDistributeDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTeamsDistributeDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTeamsDistributeDirectiveClass, OMPD_teams_distribute,
            SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(sizeof(OMPTeamsDistributeDirective),
                                         llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTeamsDistributeDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTeamsDistributeDirective *CreateEmpty(const ASTContext &C,
                                                  unsigned CollapsedNum,
                                                  unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(
            &(reinterpret_cast<Stmt *const *>(
                 &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTeamsDistributeDirectiveClass;
  }
};

/// \brief This represents '#pragma omp teams distribute simd' directive.
///
/// \code
/// #pragma omp teams simd distribute private(a,b) collapse(2)
/// \endcode
/// In this example directive '#pragma omp teams distribute simd' has clauses
/// 'private' with the variables 'a' and 'b', and 'collapse' with number '2' of
/// loops to be collapsed.
///
class OMPTeamsDistributeSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTeamsDistributeSimdDirective(SourceLocation StartLoc,
                                  SourceLocation EndLoc, unsigned CollapsedNum,
                                  unsigned N)
      : OMPExecutableDirective(OMPTeamsDistributeSimdDirectiveClass,
                               OMPD_teams_distribute_simd, StartLoc, EndLoc, N,
                               reinterpret_cast<OMPClause **>(
                                   reinterpret_cast<char *>(this) +
                                   llvm::RoundUpToAlignment(
                                       sizeof(OMPTeamsDistributeSimdDirective),
                                       llvm::alignOf<OMPClause *>())),
                               true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTeamsDistributeSimdDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(OMPTeamsDistributeSimdDirectiveClass,
                               OMPD_teams_distribute_simd, SourceLocation(),
                               SourceLocation(), N,
                               reinterpret_cast<OMPClause **>(
                                   reinterpret_cast<char *>(this) +
                                   llvm::RoundUpToAlignment(
                                       sizeof(OMPTeamsDistributeSimdDirective),
                                       llvm::alignOf<OMPClause *>())),
                               true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTeamsDistributeSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTeamsDistributeSimdDirective *CreateEmpty(const ASTContext &C,
                                                      unsigned CollapsedNum,
                                                      unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(
            &(reinterpret_cast<Stmt *const *>(
                 &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTeamsDistributeSimdDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target teams distribute' directive.
///
/// \code
/// #pragma omp target teams distribute private(a,b) collapse(2)
/// \endcode
/// In this example directive '#pragma omp target teams distribute' has clauses
/// 'private' with the variables 'a' and 'b', and 'collapse' with number '2' of
/// loops to be collapsed.
///
class OMPTargetTeamsDistributeDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetTeamsDistributeDirective(SourceLocation StartLoc,
                                    SourceLocation EndLoc,
                                    unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeDirectiveClass,
            OMPD_target_teams_distribute, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetTeamsDistributeDirective(unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeDirectiveClass,
            OMPD_target_teams_distribute, SourceLocation(), SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetTeamsDistributeDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetTeamsDistributeDirective *CreateEmpty(const ASTContext &C,
                                                        unsigned CollapsedNum,
                                                        unsigned N, EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(
            &(reinterpret_cast<Stmt *const *>(
                 &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetTeamsDistributeDirectiveClass;
  }
};

/// \brief This represents '#pragma omp target teams distribute simd' directive.
///
/// \code
/// #pragma omp target teams simd distribute private(a,b) collapse(2)
/// \endcode
/// In this example directive '#pragma omp teams distribute simd' has clauses
/// 'private' with the variables 'a' and 'b', and 'collapse' with number '2' of
/// loops to be collapsed.
///
class OMPTargetTeamsDistributeSimdDirective : public OMPExecutableDirective {
  friend class ASTStmtReader;
  unsigned CollapsedNum;
  /// \brief Build directive with the given start and end location.
  ///
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param N The number of clauses.
  ///
  OMPTargetTeamsDistributeSimdDirective(SourceLocation StartLoc,
                                        SourceLocation EndLoc,
                                        unsigned CollapsedNum, unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeSimdDirectiveClass,
            OMPD_target_teams_distribute_simd, StartLoc, EndLoc, N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}

  /// \brief Build an empty directive.
  ///
  /// \param N Number of clauses.
  ///
  explicit OMPTargetTeamsDistributeSimdDirective(unsigned CollapsedNum,
                                                 unsigned N)
      : OMPExecutableDirective(
            OMPTargetTeamsDistributeSimdDirectiveClass,
            OMPD_target_teams_distribute_simd, SourceLocation(),
            SourceLocation(), N,
            reinterpret_cast<OMPClause **>(
                reinterpret_cast<char *>(this) +
                llvm::RoundUpToAlignment(
                    sizeof(OMPTargetTeamsDistributeSimdDirective),
                    llvm::alignOf<OMPClause *>())),
            true, 5 + CollapsedNum),
        CollapsedNum(CollapsedNum) {}
  // 5 is for AssociatedStmt, NewIterVar, NewIterEnd, Init, Final
  // and CollapsedNum is for Counters.
  void setNewIterVar(Expr *V) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1] = V;
  }
  void setNewIterEnd(Expr *E) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2] = E;
  }
  void setInit(Expr *I) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3] = I;
  }
  void setFinal(Expr *F) {
    reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4] = F;
  }
  void setCounters(ArrayRef<Expr *> VL) {
    assert(VL.size() == CollapsedNum && "Number of variables is not the same "
                                        "as the number of collapsed loops.");
    std::copy(
        VL.begin(), VL.end(),
        &(reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[5]));
  }

public:
  /// \brief Creates directive with a list of \a Clauses.
  ///
  /// \param C AST context.
  /// \param StartLoc Starting location of the directive kind.
  /// \param EndLoc Ending Location of the directive.
  /// \param Clauses List of clauses.
  /// \param AssociatedStmt Statement, associated with the directive.
  ///
  static OMPTargetTeamsDistributeSimdDirective *
  Create(const ASTContext &C, SourceLocation StartLoc, SourceLocation EndLoc,
         ArrayRef<OMPClause *> Clauses, Stmt *AssociatedStmt, Expr *NewIterVar,
         Expr *NewIterEnd, Expr *Init, Expr *Final, ArrayRef<Expr *> VarCnts);

  /// \brief Creates an empty directive with the place for \a N clauses.
  ///
  /// \param C AST context.
  /// \param N The number of clauses.
  ///
  static OMPTargetTeamsDistributeSimdDirective *
  CreateEmpty(const ASTContext &C, unsigned CollapsedNum, unsigned N,
              EmptyShell);

  Expr *getNewIterVar() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() const {
    return cast_or_null<Expr>(reinterpret_cast<Stmt *const *>(
        &getClausesStorage()[getNumClauses()])[4]);
  }
  ArrayRef<Expr *> getCounters() const {
    return llvm::makeArrayRef(
        reinterpret_cast<Expr *const *>(
            &(reinterpret_cast<Stmt *const *>(
                 &getClausesStorage()[getNumClauses()])[5])),
        CollapsedNum);
  }
  unsigned getCollapsedNumber() const { return CollapsedNum; }
  Expr *getNewIterVar() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[1]);
  }
  Expr *getNewIterEnd() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[2]);
  }
  Expr *getInit() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[3]);
  }
  Expr *getFinal() {
    return cast_or_null<Expr>(
        reinterpret_cast<Stmt **>(&getClausesStorage()[getNumClauses()])[4]);
  }

  static bool classof(const Stmt *T) {
    return T->getStmtClass() == OMPTargetTeamsDistributeSimdDirectiveClass;
  }
};

} // end namespace clang

#endif
