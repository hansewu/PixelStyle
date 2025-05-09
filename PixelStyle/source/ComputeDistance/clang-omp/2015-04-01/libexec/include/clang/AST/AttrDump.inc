/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|*Attribute dumper                                                            *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

  switch (A->getKind()) {
  default:
    llvm_unreachable("Unknown attribute kind!");
    break;
  case attr::ARMInterrupt: {
    const ARMInterruptAttr *SA = cast<ARMInterruptAttr>(A);
    switch(SA->getInterrupt()) {
    case ARMInterruptAttr::IRQ:
      OS << " IRQ";
      break;
    case ARMInterruptAttr::FIQ:
      OS << " FIQ";
      break;
    case ARMInterruptAttr::SWI:
      OS << " SWI";
      break;
    case ARMInterruptAttr::ABORT:
      OS << " ABORT";
      break;
    case ARMInterruptAttr::UNDEF:
      OS << " UNDEF";
      break;
    case ARMInterruptAttr::Generic:
      OS << " Generic";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AcquireCapability: {
    OS << " " << A->getSpelling();
    const AcquireCapabilityAttr *SA = cast<AcquireCapabilityAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (AcquireCapabilityAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AcquiredAfter: {
    const AcquiredAfterAttr *SA = cast<AcquiredAfterAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (AcquiredAfterAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AcquiredBefore: {
    const AcquiredBeforeAttr *SA = cast<AcquiredBeforeAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (AcquiredBeforeAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Alias: {
    const AliasAttr *SA = cast<AliasAttr>(A);
    OS << " \"" << SA->getAliasee() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AlignMac68k: {
    break;
  }
  case attr::Aligned: {
    OS << " " << A->getSpelling();
    const AlignedAttr *SA = cast<AlignedAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    if (SA->isAlignmentExpr()) {
      lastChild();
      dumpStmt(SA->getAlignmentExpr());
    } else
      dumpType(SA->getAlignmentType()->getType());
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AlwaysInline: {
    OS << " " << A->getSpelling();
    break;
  }
  case attr::AnalyzerNoReturn: {
    break;
  }
  case attr::Annotate: {
    const AnnotateAttr *SA = cast<AnnotateAttr>(A);
    OS << " \"" << SA->getAnnotation() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ArcWeakrefUnavailable: {
    break;
  }
  case attr::ArgumentWithTypeTag: {
    OS << " " << A->getSpelling();
    const ArgumentWithTypeTagAttr *SA = cast<ArgumentWithTypeTagAttr>(A);
    OS << " " << SA->getArgumentKind()->getName();
    OS << " " << SA->getArgumentIdx();
    OS << " " << SA->getTypeTagIdx();
    if (SA->getIsPointer()) OS << " IsPointer";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AsmLabel: {
    const AsmLabelAttr *SA = cast<AsmLabelAttr>(A);
    OS << " \"" << SA->getLabel() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AssertCapability: {
    OS << " " << A->getSpelling();
    const AssertCapabilityAttr *SA = cast<AssertCapabilityAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getExpr());
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AssertExclusiveLock: {
    const AssertExclusiveLockAttr *SA = cast<AssertExclusiveLockAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (AssertExclusiveLockAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::AssertSharedLock: {
    const AssertSharedLockAttr *SA = cast<AssertSharedLockAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (AssertSharedLockAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Availability: {
    const AvailabilityAttr *SA = cast<AvailabilityAttr>(A);
    OS << " " << SA->getPlatform()->getName();
    OS << " " << SA->getIntroduced();
    OS << " " << SA->getDeprecated();
    OS << " " << SA->getObsoleted();
    if (SA->getUnavailable()) OS << " Unavailable";
    OS << " \"" << SA->getMessage() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false || false || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false || false || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Blocks: {
    const BlocksAttr *SA = cast<BlocksAttr>(A);
    switch(SA->getType()) {
    case BlocksAttr::ByRef:
      OS << " ByRef";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::C11NoReturn: {
    break;
  }
  case attr::CDecl: {
    break;
  }
  case attr::CFAuditedTransfer: {
    break;
  }
  case attr::CFConsumed: {
    break;
  }
  case attr::CFReturnsNotRetained: {
    break;
  }
  case attr::CFReturnsRetained: {
    break;
  }
  case attr::CFUnknownTransfer: {
    break;
  }
  case attr::CUDAConstant: {
    break;
  }
  case attr::CUDADevice: {
    break;
  }
  case attr::CUDAGlobal: {
    break;
  }
  case attr::CUDAHost: {
    break;
  }
  case attr::CUDALaunchBounds: {
    const CUDALaunchBoundsAttr *SA = cast<CUDALaunchBoundsAttr>(A);
    OS << " " << SA->getMaxThreads();
    OS << " " << SA->getMinBlocks();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::CUDAShared: {
    break;
  }
  case attr::CXX11NoReturn: {
    break;
  }
  case attr::CallableWhen: {
    const CallableWhenAttr *SA = cast<CallableWhenAttr>(A);
    for (CallableWhenAttr::callableStates_iterator I = SA->callableStates_begin(), E = SA->callableStates_end(); I != E; ++I) {
      switch(*I) {
    case CallableWhenAttr::Unknown:
      OS << " Unknown";
      break;
    case CallableWhenAttr::Consumed:
      OS << " Consumed";
      break;
    case CallableWhenAttr::Unconsumed:
      OS << " Unconsumed";
      break;
      }
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Capability: {
    OS << " " << A->getSpelling();
    const CapabilityAttr *SA = cast<CapabilityAttr>(A);
    OS << " \"" << SA->getName() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::CarriesDependency: {
    break;
  }
  case attr::Cleanup: {
    const CleanupAttr *SA = cast<CleanupAttr>(A);
    OS << " ";
    dumpBareDeclRef(SA->getFunctionDecl());
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Cold: {
    break;
  }
  case attr::Common: {
    break;
  }
  case attr::Const: {
    break;
  }
  case attr::Constructor: {
    const ConstructorAttr *SA = cast<ConstructorAttr>(A);
    OS << " " << SA->getPriority();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Consumable: {
    const ConsumableAttr *SA = cast<ConsumableAttr>(A);
    switch(SA->getDefaultState()) {
    case ConsumableAttr::Unknown:
      OS << " Unknown";
      break;
    case ConsumableAttr::Consumed:
      OS << " Consumed";
      break;
    case ConsumableAttr::Unconsumed:
      OS << " Unconsumed";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ConsumableAutoCast: {
    break;
  }
  case attr::ConsumableSetOnRead: {
    break;
  }
  case attr::DLLExport: {
    break;
  }
  case attr::DLLImport: {
    break;
  }
  case attr::Deprecated: {
    const DeprecatedAttr *SA = cast<DeprecatedAttr>(A);
    OS << " \"" << SA->getMessage() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Destructor: {
    const DestructorAttr *SA = cast<DestructorAttr>(A);
    OS << " " << SA->getPriority();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::EnableIf: {
    const EnableIfAttr *SA = cast<EnableIfAttr>(A);
    OS << " \"" << SA->getMessage() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getCond());
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ExclusiveTrylockFunction: {
    const ExclusiveTrylockFunctionAttr *SA = cast<ExclusiveTrylockFunctionAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || SA->args_begin() != SA->args_end();
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getSuccessValue());
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (ExclusiveTrylockFunctionAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::FallThrough: {
    break;
  }
  case attr::FastCall: {
    break;
  }
  case attr::Final: {
    OS << " " << A->getSpelling();
    break;
  }
  case attr::Flatten: {
    break;
  }
  case attr::Format: {
    const FormatAttr *SA = cast<FormatAttr>(A);
    OS << " " << SA->getType()->getName();
    OS << " " << SA->getFormatIdx();
    OS << " " << SA->getFirstArg();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::FormatArg: {
    const FormatArgAttr *SA = cast<FormatArgAttr>(A);
    OS << " " << SA->getFormatIdx();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::GNUInline: {
    break;
  }
  case attr::GuardedBy: {
    const GuardedByAttr *SA = cast<GuardedByAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getArg());
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::GuardedVar: {
    break;
  }
  case attr::Hot: {
    break;
  }
  case attr::IBAction: {
    break;
  }
  case attr::IBOutlet: {
    break;
  }
  case attr::IBOutletCollection: {
    const IBOutletCollectionAttr *SA = cast<IBOutletCollectionAttr>(A);
    OS << " " << SA->getInterface().getAsString();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::InitPriority: {
    const InitPriorityAttr *SA = cast<InitPriorityAttr>(A);
    OS << " " << SA->getPriority();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::InitSeg: {
    const InitSegAttr *SA = cast<InitSegAttr>(A);
    OS << " \"" << SA->getSection() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::IntelOclBicc: {
    break;
  }
  case attr::LockReturned: {
    const LockReturnedAttr *SA = cast<LockReturnedAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getArg());
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::LocksExcluded: {
    const LocksExcludedAttr *SA = cast<LocksExcludedAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (LocksExcludedAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::LoopHint: {
    OS << " " << A->getSpelling();
    const LoopHintAttr *SA = cast<LoopHintAttr>(A);
    switch(SA->getOption()) {
    case LoopHintAttr::Vectorize:
      OS << " Vectorize";
      break;
    case LoopHintAttr::VectorizeWidth:
      OS << " VectorizeWidth";
      break;
    case LoopHintAttr::Interleave:
      OS << " Interleave";
      break;
    case LoopHintAttr::InterleaveCount:
      OS << " InterleaveCount";
      break;
    case LoopHintAttr::Unroll:
      OS << " Unroll";
      break;
    case LoopHintAttr::UnrollCount:
      OS << " UnrollCount";
      break;
    }
    OS << " " << SA->getValue();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::MSABI: {
    break;
  }
  case attr::MSInheritance: {
    OS << " " << A->getSpelling();
    const MSInheritanceAttr *SA = cast<MSInheritanceAttr>(A);
    if (SA->getBestCase()) OS << " BestCase";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::MSP430Interrupt: {
    const MSP430InterruptAttr *SA = cast<MSP430InterruptAttr>(A);
    OS << " " << SA->getNumber();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::MSVtorDisp: {
    const MSVtorDispAttr *SA = cast<MSVtorDispAttr>(A);
    OS << " " << SA->getVdm();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Malloc: {
    break;
  }
  case attr::MaxFieldAlignment: {
    const MaxFieldAlignmentAttr *SA = cast<MaxFieldAlignmentAttr>(A);
    OS << " " << SA->getAlignment();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::MayAlias: {
    break;
  }
  case attr::MinSize: {
    break;
  }
  case attr::Mips16: {
    break;
  }
  case attr::Mode: {
    const ModeAttr *SA = cast<ModeAttr>(A);
    OS << " " << SA->getMode()->getName();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::MsStruct: {
    break;
  }
  case attr::NSConsumed: {
    break;
  }
  case attr::NSConsumesSelf: {
    break;
  }
  case attr::NSReturnsAutoreleased: {
    break;
  }
  case attr::NSReturnsNotRetained: {
    break;
  }
  case attr::NSReturnsRetained: {
    break;
  }
  case attr::Naked: {
    break;
  }
  case attr::NoCommon: {
    break;
  }
  case attr::NoDebug: {
    break;
  }
  case attr::NoDuplicate: {
    break;
  }
  case attr::NoInline: {
    break;
  }
  case attr::NoInstrumentFunction: {
    break;
  }
  case attr::NoMips16: {
    break;
  }
  case attr::NoReturn: {
    break;
  }
  case attr::NoSanitizeAddress: {
    OS << " " << A->getSpelling();
    break;
  }
  case attr::NoSanitizeMemory: {
    break;
  }
  case attr::NoSanitizeThread: {
    break;
  }
  case attr::NoSplitStack: {
    break;
  }
  case attr::NoThreadSafetyAnalysis: {
    break;
  }
  case attr::NoThrow: {
    break;
  }
  case attr::NonNull: {
    const NonNullAttr *SA = cast<NonNullAttr>(A);
    for (const auto &Val : SA->args())
      OS << " " << Val;
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::OMPLocal: {
    break;
  }
  case attr::ObjCBridge: {
    const ObjCBridgeAttr *SA = cast<ObjCBridgeAttr>(A);
    OS << " " << SA->getBridgedType()->getName();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ObjCBridgeMutable: {
    const ObjCBridgeMutableAttr *SA = cast<ObjCBridgeMutableAttr>(A);
    OS << " " << SA->getBridgedType()->getName();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ObjCBridgeRelated: {
    const ObjCBridgeRelatedAttr *SA = cast<ObjCBridgeRelatedAttr>(A);
    OS << " " << SA->getRelatedClass()->getName();
    OS << " " << SA->getClassMethod()->getName();
    OS << " " << SA->getInstanceMethod()->getName();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ObjCDesignatedInitializer: {
    break;
  }
  case attr::ObjCException: {
    break;
  }
  case attr::ObjCExplicitProtocolImpl: {
    break;
  }
  case attr::ObjCMethodFamily: {
    const ObjCMethodFamilyAttr *SA = cast<ObjCMethodFamilyAttr>(A);
    switch(SA->getFamily()) {
    case ObjCMethodFamilyAttr::OMF_None:
      OS << " OMF_None";
      break;
    case ObjCMethodFamilyAttr::OMF_alloc:
      OS << " OMF_alloc";
      break;
    case ObjCMethodFamilyAttr::OMF_copy:
      OS << " OMF_copy";
      break;
    case ObjCMethodFamilyAttr::OMF_init:
      OS << " OMF_init";
      break;
    case ObjCMethodFamilyAttr::OMF_mutableCopy:
      OS << " OMF_mutableCopy";
      break;
    case ObjCMethodFamilyAttr::OMF_new:
      OS << " OMF_new";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ObjCNSObject: {
    break;
  }
  case attr::ObjCPreciseLifetime: {
    break;
  }
  case attr::ObjCRequiresPropertyDefs: {
    break;
  }
  case attr::ObjCRequiresSuper: {
    break;
  }
  case attr::ObjCReturnsInnerPointer: {
    break;
  }
  case attr::ObjCRootClass: {
    break;
  }
  case attr::ObjCRuntimeName: {
    const ObjCRuntimeNameAttr *SA = cast<ObjCRuntimeNameAttr>(A);
    OS << " \"" << SA->getMetadataName() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::OpenCLImageAccess: {
    OS << " " << A->getSpelling();
    break;
  }
  case attr::OpenCLKernel: {
    break;
  }
  case attr::OptimizeNone: {
    break;
  }
  case attr::Overloadable: {
    break;
  }
  case attr::Override: {
    break;
  }
  case attr::Ownership: {
    OS << " " << A->getSpelling();
    const OwnershipAttr *SA = cast<OwnershipAttr>(A);
    OS << " " << SA->getModule()->getName();
    for (const auto &Val : SA->args())
      OS << " " << Val;
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Packed: {
    break;
  }
  case attr::ParamTypestate: {
    const ParamTypestateAttr *SA = cast<ParamTypestateAttr>(A);
    switch(SA->getParamState()) {
    case ParamTypestateAttr::Unknown:
      OS << " Unknown";
      break;
    case ParamTypestateAttr::Consumed:
      OS << " Consumed";
      break;
    case ParamTypestateAttr::Unconsumed:
      OS << " Unconsumed";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Pascal: {
    break;
  }
  case attr::Pcs: {
    const PcsAttr *SA = cast<PcsAttr>(A);
    switch(SA->getPCS()) {
    case PcsAttr::AAPCS:
      OS << " AAPCS";
      break;
    case PcsAttr::AAPCS_VFP:
      OS << " AAPCS_VFP";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::PnaclCall: {
    break;
  }
  case attr::PtGuardedBy: {
    const PtGuardedByAttr *SA = cast<PtGuardedByAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getArg());
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::PtGuardedVar: {
    break;
  }
  case attr::Pure: {
    break;
  }
  case attr::ReleaseCapability: {
    OS << " " << A->getSpelling();
    const ReleaseCapabilityAttr *SA = cast<ReleaseCapabilityAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (ReleaseCapabilityAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ReqdWorkGroupSize: {
    const ReqdWorkGroupSizeAttr *SA = cast<ReqdWorkGroupSizeAttr>(A);
    OS << " " << SA->getXDim();
    OS << " " << SA->getYDim();
    OS << " " << SA->getZDim();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::RequiresCapability: {
    OS << " " << A->getSpelling();
    const RequiresCapabilityAttr *SA = cast<RequiresCapabilityAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (RequiresCapabilityAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ReturnTypestate: {
    const ReturnTypestateAttr *SA = cast<ReturnTypestateAttr>(A);
    switch(SA->getState()) {
    case ReturnTypestateAttr::Unknown:
      OS << " Unknown";
      break;
    case ReturnTypestateAttr::Consumed:
      OS << " Consumed";
      break;
    case ReturnTypestateAttr::Unconsumed:
      OS << " Unconsumed";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ReturnsNonNull: {
    break;
  }
  case attr::ReturnsTwice: {
    break;
  }
  case attr::ScopedLockable: {
    break;
  }
  case attr::Section: {
    OS << " " << A->getSpelling();
    const SectionAttr *SA = cast<SectionAttr>(A);
    OS << " \"" << SA->getName() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::SelectAny: {
    break;
  }
  case attr::Sentinel: {
    const SentinelAttr *SA = cast<SentinelAttr>(A);
    OS << " " << SA->getSentinel();
    OS << " " << SA->getNullPos();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::SetTypestate: {
    const SetTypestateAttr *SA = cast<SetTypestateAttr>(A);
    switch(SA->getNewState()) {
    case SetTypestateAttr::Unknown:
      OS << " Unknown";
      break;
    case SetTypestateAttr::Consumed:
      OS << " Consumed";
      break;
    case SetTypestateAttr::Unconsumed:
      OS << " Unconsumed";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::SharedTrylockFunction: {
    const SharedTrylockFunctionAttr *SA = cast<SharedTrylockFunctionAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || SA->args_begin() != SA->args_end();
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getSuccessValue());
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (SharedTrylockFunctionAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::StdCall: {
    break;
  }
  case attr::SysVABI: {
    break;
  }
  case attr::TLSModel: {
    const TLSModelAttr *SA = cast<TLSModelAttr>(A);
    OS << " \"" << SA->getModel() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::TestTypestate: {
    const TestTypestateAttr *SA = cast<TestTypestateAttr>(A);
    switch(SA->getTestState()) {
    case TestTypestateAttr::Consumed:
      OS << " Consumed";
      break;
    case TestTypestateAttr::Unconsumed:
      OS << " Unconsumed";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::ThisCall: {
    break;
  }
  case attr::Thread: {
    break;
  }
  case attr::TransparentUnion: {
    break;
  }
  case attr::TryAcquireCapability: {
    OS << " " << A->getSpelling();
    const TryAcquireCapabilityAttr *SA = cast<TryAcquireCapabilityAttr>(A);
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || SA->args_begin() != SA->args_end();
    setMoreChildren(MoreChildren);
    lastChild();
    dumpStmt(SA->getSuccessValue());
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    for (TryAcquireCapabilityAttr::args_iterator I = SA->args_begin(), E = SA->args_end(); I != E; ++I) {
      if (I + 1 == E)
        lastChild();
      dumpStmt(*I);
    }
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::TypeTagForDatatype: {
    const TypeTagForDatatypeAttr *SA = cast<TypeTagForDatatypeAttr>(A);
    OS << " " << SA->getArgumentKind()->getName();
    OS << " " << SA->getMatchingCType().getAsString();
    if (SA->getLayoutCompatible()) OS << " LayoutCompatible";
    if (SA->getMustBeNull()) OS << " MustBeNull";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::TypeVisibility: {
    const TypeVisibilityAttr *SA = cast<TypeVisibilityAttr>(A);
    switch(SA->getVisibility()) {
    case TypeVisibilityAttr::Default:
      OS << " Default";
      break;
    case TypeVisibilityAttr::Hidden:
      OS << " Hidden";
      break;
    case TypeVisibilityAttr::Protected:
      OS << " Protected";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Unavailable: {
    const UnavailableAttr *SA = cast<UnavailableAttr>(A);
    OS << " \"" << SA->getMessage() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Unused: {
    break;
  }
  case attr::Used: {
    break;
  }
  case attr::Uuid: {
    const UuidAttr *SA = cast<UuidAttr>(A);
    OS << " \"" << SA->getGuid() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::VecReturn: {
    break;
  }
  case attr::VecTypeHint: {
    const VecTypeHintAttr *SA = cast<VecTypeHintAttr>(A);
    OS << " " << SA->getTypeHint().getAsString();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::Visibility: {
    const VisibilityAttr *SA = cast<VisibilityAttr>(A);
    switch(SA->getVisibility()) {
    case VisibilityAttr::Default:
      OS << " Default";
      break;
    case VisibilityAttr::Hidden:
      OS << " Hidden";
      break;
    case VisibilityAttr::Protected:
      OS << " Protected";
      break;
    }
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::WarnUnused: {
    break;
  }
  case attr::WarnUnusedResult: {
    break;
  }
  case attr::Weak: {
    break;
  }
  case attr::WeakImport: {
    break;
  }
  case attr::WeakRef: {
    const WeakRefAttr *SA = cast<WeakRefAttr>(A);
    OS << " \"" << SA->getAliasee() << "\"";
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::WorkGroupSizeHint: {
    const WorkGroupSizeHintAttr *SA = cast<WorkGroupSizeHintAttr>(A);
    OS << " " << SA->getXDim();
    OS << " " << SA->getYDim();
    OS << " " << SA->getZDim();
    bool OldMoreChildren = hasMoreChildren();
    bool MoreChildren;
    MoreChildren = OldMoreChildren || false || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren || false;
    setMoreChildren(MoreChildren);
    MoreChildren = OldMoreChildren;
    setMoreChildren(MoreChildren);
    setMoreChildren(OldMoreChildren);
    break;
  }
  case attr::X86ForceAlignArgPointer: {
    break;
  }
  }
