SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[vrvPMContractAnalysisDDBilledAmts]

/*********************************************************************
 * Created By:	JH 3/17/10 - Initial version for customer 
 *				report PM Contract Analysis DD
 * Modfied By:  #138909 HH 1/5/11 - No modification, created in VPDev640 
 *				for customer report PM Contract Analysis DD to 
 *				become Standard report in PM
 *
 *	Used on PM Contract Analysis DD report, grant all on vrvBilledAmts to public
 *
 *********************************************************************/
 
AS


SELECT JCID.JCCo
		, JCID.Mth
		, JCID.Contract
		, ARTH.CustGroup
		, ARTH.Customer
		, ARTH.TransDate
		, JCID.ARInvoice
		, JCID.Description
		, JCID.BilledAmt
		, AttachmentID=''
		, JBAtttachID=''
		, ARAttachDesc=''
		, JBAttachDesc=''
FROM JCID WITH(NOLOCK)
	LEFT JOIN ARTH WITH(NOLOCK) ON JCID.ARCo=ARTH.ARCo AND JCID.Mth=ARTH.Mth AND JCID.ARTrans=ARTH.ARTrans 
WHERE JCID.BilledAmt<>0

UNION ALL

SELECT JCID.JCCo
		, JCID.Mth
		, JCID.Contract
		, ARTH.CustGroup
		, ARTH.Customer
		, ARTH.TransDate
		, JCID.ARInvoice
		, JCID.Description
		, BilledAmt=0
		, HQAT.AttachmentID
		, HQAT_JB.AttachmentID
		, HQAT.Description
		, HQAT_JB.Description
FROM JCID WITH(NOLOCK) 
	LEFT JOIN ARTH WITH(NOLOCK) ON JCID.ARCo=ARTH.ARCo AND JCID.Mth=ARTH.Mth AND JCID.ARTrans=ARTH.ARTrans 
	LEFT JOIN ARCM WITH(NOLOCK) ON ARTH.CustGroup=ARCM.CustGroup AND ARTH.Customer=ARCM.Customer 
	LEFT JOIN HQAT WITH(NOLOCK) ON  ARTH.ARCo=HQAT.HQCo AND ARTH.UniqueAttchID=HQAT.UniqueAttchID 
	LEFT JOIN JBIN WITH(NOLOCK) ON  ARTH.ARCo=JBIN.JBCo AND ARTH.ARTrans=JBIN.ARTrans AND ARTH.Mth=JBIN.BillMonth 
	LEFT JOIN HQAT HQAT_JB with(nolock) on  JBIN.JBCo=HQAT_JB.HQCo AND JBIN.UniqueAttchID=HQAT_JB.UniqueAttchID
WHERE JCID.BilledAmt<>0



GO
GRANT SELECT ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [public]
GRANT INSERT ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [public]
GRANT DELETE ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [public]
GRANT SELECT ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMContractAnalysisDDBilledAmts] TO [Viewpoint]
GO
