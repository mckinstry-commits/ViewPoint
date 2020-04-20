SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            proc [dbo].[bspHQAPEFTExport]
    /************************************
    * Created: 10/27/99 GF
    * Modified: 04/04/01 TV : Procedure was looking up info for Company 1 evertime
    *           9/10/01 MV - Issue 10997 EFT Addenda records
    *           10/01/01 MV - added taxformcode and employee to result set
    *			  3/1/02 EN - issue 12974 - added cm acct and cm reference to the WHERE criteria
    *			  3/25/03 MV - #20518 - turn nulls into 0 for AddendaFormat and AddendaTypeId
    *			  4/2/03 MV - #20518 - added a.BatchSeq to order by clause so download matches audit list.
    *			  04/13/04 MV - #24241 - join to bCMAC on CMCo not the ap batch company
    *			12/19/2004 Dan F 119669 - Remove 'AddendaFormat' from order by clause for SQL 9.0 - 2005
    *			07/09/2007 MV - #124967 - use CM Company's HQCO.Name not AP Company's HQCO.Name
	*			11/12/08 MV - #129234 - select domestic EFT and International EFT payment information into a table variable
    * This SP is used in HQExport form frmAPEFTExport.
    * Any changes here will require changes to the form.
    *
    ***********************************/
    (@apco bCompany, @currmonth bMonth, @batchid bBatchID, @cmacct bCMAcct, @cmref bCMRef)
  
   as
   set nocount on
  
	declare @table TABLE(APCo int,BatchId int ,PayMethod varchar(1),CMRef bCMRef,
	VendorGroup bGroup ,Vendor bVendor, VendorName varchar(60),Amount bDollar ,EFT varchar(1), VendorRoutingId varchar(34), 
	VendorBankAcct varchar(35), AcctType varchar(1) , CMACBankAcct varchar(30), ImmedDest varchar(10),ImmedOrig varchar(10),
	CompanyId varchar(10),CMACRoutingId varchar(10), ServiceClass varchar(3),CMACAcctType varchar(1),CMACBankName varchar(30),
	ODFI varchar(10),CompanyName varchar(60),AssignBank varchar(60),CMACBatchHeader varchar(94),AddendaTypeId tinyint,
	FedTaxId varchar(12), AddendaFormat tinyint,FedTaxFormCode varchar(10) null, Employee int,BatchSeq int,IATYN bYN,ISODestCountryCode varchar(2) null,
	GateWayOperRDFI varchar(8) null,RDFIBankName varchar(35) null, RDFIIdentNbrQual varchar(2) null,BranchCountryCode varchar(3) null,
	VendorStreet varchar(60) null,VendorCity varchar(30) null, VendorState varchar(4) null, VendorCountry varchar(2) null,
	VendorPostal bZip null,OrigStreet varchar(60) null,OrigCity varchar(30) null, OrigState varchar(4) null,
	OrigCountry varchar(2) null,OrigPostal bZip null)

	-- Get domestic EFT payment info
	insert into @table (APCo,BatchId,PayMethod,CMRef,VendorGroup,Vendor, VendorName,Amount,EFT, VendorRoutingId,VendorBankAcct,
		AcctType, CMACBankAcct, ImmedDest, ImmedOrig, CompanyId,CMACRoutingId, ServiceClass,CMACAcctType,CMACBankName,ODFI,CompanyName,
		AssignBank,CMACBatchHeader,AddendaTypeId,FedTaxId, AddendaFormat,FedTaxFormCode, Employee,BatchSeq,
		IATYN,ISODestCountryCode,GateWayOperRDFI,
		RDFIBankName, RDFIIdentNbrQual,BranchCountryCode,VendorStreet,VendorCity, VendorState, VendorCountry,VendorPostal,
		OrigStreet,OrigCity, OrigState,OrigCountry,OrigPostal)

	select a.Co, a.BatchId,a.PayMethod, a.CMRef,a.VendorGroup,a.Vendor,a.Name, a.Amount, b.EFT, b.RoutingId,b.BankAcct,
  	   b.AcctType,c.BankAcct, c.ImmedDest, c.ImmedOrig,c.CompanyId, c.RoutingId, c.ServiceClass,
  	   c.AcctType, c.BankName, c.DFI, e.Name,CASE isnull(c.AssignBank,'') WHEN '' THEN e.Name ELSE c.AssignBank END,
  	   c.BatchHeader, 'AddendaTypeId'= isnull(a.AddendaTypeId,0),e.FedTaxId, 
        'AddendaFormat'= (case a.AddendaTypeId when 1 then 1 when 2 then 1 when 3 then 2 else 0 end),
        a.TaxFormCode, a.Employee, a.BatchSeq,b.IATYN,b.ISODestinationCountryCode,b.GatewayOperatorRDFIIdent,b.RDFIBankName,
		b.RDFIIdentNbrQualifier,b.BranchCountryCode,b.Address, b.City,b.State,b.Country,b.Zip,e.Address,e.City,e.State,
		e.Country,e.Zip
	from bAPPB a
	   INNER JOIN bAPVM b ON a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor
	   LEFT OUTER JOIN bCMAC c ON a.CMCo = c.CMCo and a.CMAcct = c.CMAcct	
	   LEFT OUTER JOIN bHQCO e ON e.HQCo=c.CMCo 
	WHERE a.Co = @apco and a.Mth >= @currmonth and a.Mth <= @currmonth
	   and a.BatchId = @batchid and a.PayMethod = 'E' and a.CMAcct = @cmacct and a.CMRef=@cmref and b.IATYN='N' 
	ORDER BY  a.AddendaTypeId, a.Vendor, a.BatchSeq

	--Get Internation EFT payment info
	insert into @table (APCo,BatchId,PayMethod,CMRef,VendorGroup,Vendor, VendorName,Amount,EFT, VendorRoutingId,VendorBankAcct,
		AcctType, CMACBankAcct, ImmedDest, ImmedOrig, CompanyId,CMACRoutingId, ServiceClass,CMACAcctType,CMACBankName,ODFI,CompanyName,
		AssignBank,CMACBatchHeader,AddendaTypeId,FedTaxId, AddendaFormat,FedTaxFormCode, Employee,BatchSeq,
		IATYN,ISODestCountryCode,GateWayOperRDFI,
		RDFIBankName, RDFIIdentNbrQual,BranchCountryCode,VendorStreet,VendorCity, VendorState, VendorCountry,VendorPostal,
		OrigStreet,OrigCity, OrigState,OrigCountry,OrigPostal)

	select a.Co, a.BatchId,a.PayMethod, a.CMRef,a.VendorGroup,a.Vendor,a.Name, a.Amount, b.EFT, b.RoutingId,b.BankAcct,
  	   b.AcctType,c.BankAcct, c.ImmedDest, c.ImmedOrig,c.CompanyId, c.RoutingId, c.ServiceClass,
  	   c.AcctType, c.BankName, c.DFI, e.Name,CASE isnull(c.AssignBank,'') WHEN '' THEN e.Name ELSE c.AssignBank END,
  	   c.BatchHeader, 'AddendaTypeId'= 0,e.FedTaxId, 
        'AddendaFormat'= 0,
        a.TaxFormCode, a.Employee, a.BatchSeq,b.IATYN,b.ISODestinationCountryCode,b.GatewayOperatorRDFIIdent,b.RDFIBankName,
		b.RDFIIdentNbrQualifier,b.BranchCountryCode,b.Address, b.City,b.State,b.Country,b.Zip,e.Address,e.City,e.State,
		e.Country,e.Zip
	from bAPPB a
	   INNER JOIN bAPVM b ON a.VendorGroup = b.VendorGroup and a.Vendor = b.Vendor
	   LEFT OUTER JOIN bCMAC c ON a.CMCo = c.CMCo and a.CMAcct = c.CMAcct	
	   LEFT OUTER JOIN bHQCO e ON e.HQCo=c.CMCo 
	WHERE a.Co = @apco and a.Mth >= @currmonth and a.Mth <= @currmonth
	   and a.BatchId = @batchid and a.PayMethod = 'E' and a.CMAcct = @cmacct and a.CMRef=@cmref and b.IATYN='Y' 
	ORDER BY  b.ISODestinationCountryCode, a.Vendor, a.BatchSeq

	select * from @table

return

GO
GRANT EXECUTE ON  [dbo].[bspHQAPEFTExport] TO [public]
GO
