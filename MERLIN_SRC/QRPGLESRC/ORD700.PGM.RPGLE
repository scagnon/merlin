**FREE
//%METADATA                                                                          *
// %TEXT                                                                             *
//%EMETADATA                                                                         *
Ctl-Opt dftactgrp(*no);

Dcl-F article1   Usage(*Update:*Delete) Keyed;

/COPY ../QPROTOSRC/LOG.RPGLEINC

Dcl-Pr UpdArt;
  qty             Packed(5:0)     value;
  id              like(new.ODARID);
End-Pr;

Dcl-S pDs_PiParm_001  Pointer;
Dcl-Ds PARM1
             Based(pDs_PiParm_001);
// Physical file name
  FNAME           Char(10);
// Physical file library
  LNAME           Char(10);
// Member name
  MNAME           Char(10);
// Trigger event 1=Ins, 2=Del, 3=Upd
  TEVEN           Char(1);
// Trigger time  1=After, 2=Before
  TTIME           Char(1);
// Commit lock level
  CMTLCK          Char(1);
// Reserved
  *n              Char(3);
// CCSID
  CCSID           Int(10);
// Reserved
  *n              Char(8);
// Offset to the original record
  OLDOFF          Int(10);
// length of the original record
  OLDLEN          Int(10);
// Offset to the original record null byte map
  ONOFF           Int(10);
// length of the null byte map
  ONLEN           Int(10);
// Offset to the new record
  NEWOFF          Int(10);
// length of the new record
  NEWLEN          Int(10);
// Offset to the new record null byte map
  NNOFF           Int(10);
// length of the null byte map
  NNLEN           Int(10);
End-Ds;

// Trigger Buffer Length

// Record to be inserted or new values
Dcl-Ds NEW ExtName('DETORD')
           qualified
           based(pn);
End-Ds;

// Record to be deleted or old values
Dcl-Ds OLD ExtName('DETORD')
           qualified
           based(po);
End-Ds;
// Prototype for ORD700
Dcl-Pr Pgm_ORD700 ExtPgm('ORD700');
  Ds_PiParm_001   LikeDs(PARM1);
  PARM2           Int(10);
End-Pr;
// Procedure interface for ORD700
Dcl-Pi Pgm_ORD700;
  Ds_PiParm_001   LikeDs(PARM1);
  PARM2           Int(10);
End-Pi;

// SET UP THE ENTRY PARAMETER LIST.

pDs_PiParm_001 = %Addr(Ds_PiParm_001);
If               %parms = 0;
  *INLR = '1';
  Return;
EndIf;
Select;
  When teven = '1';
    pn = %addr(parm1) + newoff;
    UpdArt(new.odqty:new.odarid);
  When teven = '2';
    po = %addr(parm1) + oldoff;
    CallP(e) addlogEntry('ORD700:Order Line deleted ' +
        %char(Old.odorid) + ' ' + %char(Old.odline)
         + ' article : ' + old.odarid
         + ' quantity : ' + %char(old.odqty));
    UpdArt(-Old.odqty + Old.odqtyliv:old.odarid);
  When teven = '3';
    pn = %addr(parm1) + newoff;
    po = %addr(parm1) + oldoff;
    If new.odarid = Old.odarid;
      UpdArt((New.odqty - Old.odqty)
           - (New.odqtyLiv - Old.odqtyLiv)
          :new.odarid);
    Else;
      UpdArt(new.odqty- new.odqtyliv:new.odarid);
      UpdArt(-Old.odqty + Old.odqtyliv:old.odarid);
    EndIf;
EndSl;
Return;

Dcl-Proc UpdArt;
  Dcl-Pi UpdArt;
    qty             Packed(5:0)     value;
    id              like(new.ODARID);
  End-Pi;
  If qty = 0;
    Return;
  EndIf;
  Chain id article1;
  If not %found;
    Return;
  EndIf;
  ARCUSQTY += qty;
  Update farti;
End-Proc UpdArt;