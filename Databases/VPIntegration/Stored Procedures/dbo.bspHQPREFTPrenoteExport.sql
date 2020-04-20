SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQPREFTPrenoteExport]
 /************************************
  * Created: 10/21/99 GF
  * Modified: 5/10/02 EN issue 17306 include Batch Header and Assign Bank fields in return values
  *			 7/22/02 EN #18039 add 'left' keyword to bHQCO and bCMAC joins to include empl info in results
  *			7/10/07 MV #124986 use HQCO.Name linked to CMCo not APCo
  *			DAN SO 08/25/09 - Issue #135071 - new Discretionary column
  *
  * This SP is used in HQExport form frmPREFTPreNoteExport.
  * Any changes here will require changes to the form.
  *
  ***********************************/
   (@PRCo bCompany, @PRGroup bGroup)
 
   as
   create table #PREFT
 
   (PRCo		tinyint null,
   PRGroup		tinyint null,
   Employee		int	null,
   LastName		varchar(30) null,
   FirstName	varchar(30)	null,
   MidName		varchar(15)	null,
   Seq			numeric	null,
   RoutingId	varchar(10)	null,
   BankAcct		varchar(30)	null,
   Type			char(1)	null,
   Status		char(1)	null,
   Frequency	varchar(10)	null,
   Method		varchar(1)	null,
   Pct			numeric(12,6)	null,
   Amount		numeric(12,2)	null,
 
   CMCo				tinyint null,
   CMAcct			numeric	null,
   CMBankAcct		varchar(30)	null,
   ImmedDest		varchar(10)	null,
   ImmedOrig		varchar(10) Null,
   CMDiscretionary	varchar(20)	NULL,		--#135071
   CMCompanyId		varchar(10)	null,
   BankName			varchar(30)	null,
   CMDFI			varchar(10)	null,
   CMRoutingId		varchar(10)	Null,
   ServiceClass		varchar(3)	Null,
   AcctType			char   (1)	Null,
 
   )
 
   /*insert CMAC Bank Information*/
   insert into #PREFT
   (PRCo,PRGroup, CMCo, CMAcct, CMBankAcct, ImmedDest, ImmedOrig, 
    CMCompanyId, BankName, CMDFI, CMRoutingId, ServiceClass, AcctType,
    CMDiscretionary
   )
 
   select bPRGR.PRCo, bPRGR.PRGroup, bCMAC.CMCo, bCMAC.CMAcct, bCMAC.BankAcct, bCMAC.ImmedDest, bCMAC.ImmedOrig,
		  bCMAC.CompanyId, bCMAC.BankName, bCMAC.DFI, bCMAC.RoutingId, bCMAC.ServiceClass, bCMAC.AcctType,
		  bCMAC.Discretionary
 
   from bPREH PREH
   Join bPRGR on bPRGR.PRCo=PREH.PRCo and bPRGR.PRGroup=PREH.PRGroup
   Join bCMAC  on bPRGR.CMCo=bCMAC.CMCo and bPRGR.CMAcct=bCMAC.CMAcct
 
   where PREH.PRCo=@PRCo and bPRGR.PRGroup=@PRGroup
 
   Group by bPRGR.PRCo, bPRGR.PRGroup, bCMAC.CMCo, bCMAC.CMAcct, bCMAC.BankAcct, bCMAC.ImmedDest, bCMAC.ImmedOrig,
			bCMAC.CompanyId, bCMAC.BankName, bCMAC.DFI, bCMAC.RoutingId, bCMAC.ServiceClass, bCMAC.AcctType,
			bCMAC.Discretionary
 
   /* insert PREH records into PREFT*/
   insert into #PREFT
 
   (PRCo, PRGroup, Employee,LastName, FirstName, MidName, Seq, RoutingId, BankAcct, Type,  Status
  )
 
   select PREH.PRCo, PREH.PRGroup, PREH.Employee,PREH.LastName,PREH.FirstName,PREH.MidName,
		0, PREH.RoutingId, PREH.BankAcct, PREH.AcctType, PREH.DirDeposit
 
    from PREH
 
   where PREH.PRCo=@PRCo and PREH.PRGroup=@PRGroup and PREH.DirDeposit='P'
 
    /*insert PRDD records into PREFT*/
   insert into #PREFT
   (PRCo, PRGroup, Employee,LastName, FirstName, MidName, Seq, RoutingId, BankAcct, Type,  Status,Frequency, Method, Pct, Amount
  )
 
  select bPRDD.PRCo, PREH.PRGroup, bPRDD.Employee, PREH.LastName,PREH.FirstName,PREH.MidName,bPRDD.Seq, bPRDD.RoutingId, bPRDD.BankAcct, bPRDD.Type,
   bPRDD.Status, bPRDD.Frequency, bPRDD.Method, bPRDD.Pct, bPRDD.Amount
 
   from bPRDD
   Left Join PREH on bPRDD.PRCo=PREH.PRCo and bPRDD.Employee=PREH.Employee
 
   where bPRDD.PRCo=@PRCo and PREH.PRGroup=@PRGroup and bPRDD.Status='P'
 
 
 
    /*select results*/
   select
 
   a.Employee, a.LastName, a.FirstName, a.MidName, a.RoutingId, a.BankAcct,
   a.Type, a.CMBankAcct, a.ImmedDest, a.ImmedOrig, a.CMCompanyId, a.BankName,
   a.CMDFI, a.CMRoutingId, a.ServiceClass, a.AcctType, bHQCO.Name, 
   CASE isnull(bCMAC.AssignBank,'') WHEN '' THEN bHQCO.Name ELSE bCMAC.AssignBank END, bCMAC.BatchHeader,
   a.CMDiscretionary
 
   from #PREFT a
 
   left Join bHQCO on bHQCO.HQCo=a.CMCo/*a.PRCo*/
   left Join bCMAC on a.CMCo = bCMAC.CMCo and a.CMAcct = bCMAC.CMAcct

GO
GRANT EXECUTE ON  [dbo].[bspHQPREFTPrenoteExport] TO [public]
GO
