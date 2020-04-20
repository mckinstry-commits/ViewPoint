SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE        proc [dbo].[bspHQPREFTExport]
     /************************************
     * Created: 10/27/99 GF
     * Modified: DANF 08/23/00
     *		TV 04/04/01 : Procedure was looking up Company 1 paramiters everytime
     *      DANF 11/2/01 : Correct order of BatchHeader and Assigned Bank Name.
     *		EN 4/23/02 - issue 16983 was comparing d.CMCo to @prco in bCMAC join when it s/b comparing it to CMCo from bPRSQ
     *							... also needed to use b.CMCo rather than a.PRCo to get company name from bHQCO
	 *		mh 10/02/2008 - Issue 127267 - Added AUBankShortName, AUCustomerNumber, AUBSB, 
	 *						AUAccountName, AUContraRequiredYN to select statement.
	 *		mh 03/02/2009 - Issue 127223
	 *		DAN SO 08/25/2009 - Issue: #135071 - retrieve new Discretionary column
	 *		MV	01/05/11 - #142768 - added CAShortName and CALongName
	 *		EN 2/22/11 #143236  return CAEFTFormat, Employee # label and Pay Seq
	 *		EN 3/4/2011 #143404 revised some field labels to work with AP EFT coding needs
	 *		EN 3/10/2011 #143236/#143404 sort results by Employee # and remove Pay Seq from select list because need to generate payment # in front-end
	 *		MV 07/26/11 #144182 - return CARBCFileDescriptor for CA RBC bank.
     *
     * This SP is used in HQExport form frmPREFTExport.
     * Any changes here will require changes to the form.
     *
     ***********************************/

	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @cmref bCMRef)
   
	AS
	SET NOCOUNT ON

	SELECT a.PRCo, 
		   a.PRGroup, 
		   a.PREndDate, 
		   a.Employee AS 'CustomerNumber',  
		   a.RoutingId AS 'PayeeRoutingId', 
		   a.BankAcct AS 'PayeeBankAcct',  
		   a.Type AS 'EmpType', 
		   convert(decimal(16,2),a.Amt) AS 'Amt',  
		   b.CMRef AS 'EmpCMRef',  
		   c.LastName AS 'EmpLastName', 
		   c.FirstName AS 'EmpFirstName',  
		   c.MidName AS 'EmpMidName',  
		   d.BankAcct AS 'CMBankAcct', 
		   d.ImmedDest AS 'CMImmedDest',  
		   d.ImmedOrig AS 'CMImmedOrig',  
		   d.CompanyId AS 'CMCompanyId', 
		   d.BankName AS 'CMBankName',  
		   d.DFI AS 'CMDFI',  
		   d.RoutingId AS 'CMRoutingId',
		   d.ServiceClass AS 'CMServiceClass',  
		   d.AcctType AS 'CMAcctType',  
		   e.Name AS 'HQName', 
		   CASE isnull(d.AssignBank,'') WHEN '' THEN e.Name ELSE d.AssignBank END AS 'AssignBank', 
		   d.BatchHeader AS 'CMBatchHeader',   
		   d.Discretionary AS 'CMDiscretionary',
		   d.AUBankShortName,   
		   d.AUCustomerNumber,   
		   d.AUBSB,   
		   d.AUAccountName, 
		   d.AUContraRequiredYN,   
		   d.AUReference,   
		   d.CAOriginatorId,  
		   d.CADestDataCentre,  
		   d.CACurrencyCode, 
		   d.CACMRoutingNbr, isnull(c.FirstName,'') + ' ' + isnull(c.MidName,'') + ' ' + isnull(c.LastName,'') AS 'PayeeName',
		   d.CAShortName,   
		   d.CALongName,   
		   d.CAEFTFormat,
		   d.CARBCFileDescriptor
	FROM bPRDS a 
	INNER JOIN bPRSQ b ON a.PRCo = b.PRCo 
						  AND a.PRGroup = b.PRGroup 
						  AND a.PREndDate = b.PREndDate
						  AND a.Employee = b.Employee 
						  AND a.PaySeq = b.PaySeq
	INNER JOIN bHQCO e ON b.CMCo = e.HQCo
	LEFT OUTER JOIN bPREH c ON a.PRCo = c.PRCo 
						  AND a.Employee = c.Employee
	LEFT OUTER JOIN bCMAC d ON b.CMCo = d.CMCo 
						  AND b.CMAcct = d.CMAcct
	WHERE a.PRCo = @prco 
		  AND a.PRGroup = @prgroup 
		  AND a.PREndDate = @prenddate
		  AND b.CMRef = @cmref
	ORDER BY a.PRCo, a.PRGroup, a.PREndDate, a.Employee


GO
GRANT EXECUTE ON  [dbo].[bspHQPREFTExport] TO [public]
GO
