/*

SELECT * FROM SLHD WHERE SLCo=1 AND SL='10659-001005'


SELECT 
	'select ''' + so.NAME + ''',* from [' + so.name + '] (nolock) WHERE SL=''10659-001005'''
FROM 
	sysobjects so join
	syscolumns sc ON
		so.id=sc.id
	WHERE 
		sc.name='SL'
	AND so.type='U' 
ORDER BY
	so.name

--select 'APUL_20141204_BU',* from [APUL_20141204_BU] (nolock) WHERE SL='10659-001005'
--select 'APUL_20141229_BACKUP',* from [APUL_20141229_BACKUP] (nolock) WHERE SL='10659-001005'
--select 'APUL_20150107_LWO',* from [APUL_20150107_LWO] (nolock) WHERE SL='10659-001005'
--select 'OpenRetg',* from [OpenRetg] (nolock) WHERE SL='10659-001005'
--select 'bAPJC',* from [bAPJC] (nolock) WHERE SL='10659-001005'
----select 'bAPJC_VU16145',* from [bAPJC_VU16145] (nolock) WHERE SL='10659-001005'
----select 'bAPJC_VU16145_Reversals',* from [bAPJC_VU16145_Reversals] (nolock) WHERE SL='10659-001005'
--select 'bAPLB',* from [bAPLB] (nolock) WHERE SL='10659-001005'
----select 'bAPLB_VU16145_MismatchedVendors',* from [bAPLB_VU16145_MismatchedVendors] (nolock) WHERE SL='10659-001005'
--select 'bAPPB',* from [bAPPB] (nolock) WHERE SL='10659-001005'
--select 'bAPRL',* from [bAPRL] (nolock) WHERE SL='10659-001005'
--select 'bAPTL',* from [bAPTL] (nolock) WHERE SL='10659-001005'
--select 'bAPTL_bak_20141219',* from [bAPTL_bak_20141219] (nolock) WHERE SL='10659-001005'
--select 'bAPUL',* from [bAPUL] (nolock) WHERE SL='10659-001005'
--select 'bJBID',* from [bJBID] (nolock) WHERE SL='10659-001005'
--select 'bJBIDTMWork',* from [bJBIDTMWork] (nolock) WHERE SL='10659-001005'
--select 'bJCCB',* from [bJCCB] (nolock) WHERE SL='10659-001005'
-- //////  select 'bJCCD',* from [bJCCD] (nolock) WHERE SL='10659-001005'
--select 'bJCCD_PO_bak_20150119',* from [bJCCD_PO_bak_20150119] (nolock) WHERE SL='10659-001005'
--select 'bJCCD_bak_20141219',* from [bJCCD_bak_20141219] (nolock) WHERE SL='10659-001005'
--select 'bPMBC',* from [bPMBC] (nolock) WHERE SL='10659-001005'
--select 'bPMDH',* from [bPMDH] (nolock) WHERE SL='10659-001005'
--select 'bPMDZ',* from [bPMDZ] (nolock) WHERE SL='10659-001005'
select 'bPMSL',* from [bPMSL] (nolock) WHERE SL='10659-001005'
--select 'bPMSL_bak_20141119',* from [bPMSL_bak_20141119] (nolock) WHERE SL='10659-001005'
--select 'bPMSL_bak_20141205',* from [bPMSL_bak_20141205] (nolock) WHERE SL='10659-001005'
select 'bPMSS',* from [bPMSS] (nolock) WHERE SL='10659-001005'
--select 'bPORJ',* from [bPORJ] (nolock) WHERE SL='10659-001005'
--select 'bSLCA',* from [bSLCA] (nolock) WHERE SL='10659-001005'
--select 'bSLCB',* from [bSLCB] (nolock) WHERE SL='10659-001005'
--select 'bSLCD',* from [bSLCD] (nolock) WHERE SL='10659-001005'
select 'bSLCT',* from [bSLCT] (nolock) WHERE SL='10659-001005'
--select 'bSLHB',* from [bSLHB] (nolock) WHERE SL='10659-001005'
select 'bSLHD',* from [bSLHD] (nolock) WHERE SL='10659-001005'
--select 'bSLHD_bak_20141119',* from [bSLHD_bak_20141119] (nolock) WHERE SL='10659-001005'
--select 'bSLIA',* from [bSLIA] (nolock) WHERE SL='10659-001005'
--select 'bSLIT',* from [bSLIT] (nolock) WHERE SL='10659-001005'
--select 'bSLIT_bak_10326_001001',* from [bSLIT_bak_10326_001001] (nolock) WHERE SL='10659-001005'
--select 'bSLIT_bak_20141119',* from [bSLIT_bak_20141119] (nolock) WHERE SL='10659-001005'
--select 'bSLWH',* from [bSLWH] (nolock) WHERE SL='10659-001005'
--select 'bSLWI',* from [bSLWI] (nolock) WHERE SL='10659-001005'
--select 'bSLXA',* from [bSLXA] (nolock) WHERE SL='10659-001005'
--select 'bSLXB',* from [bSLXB] (nolock) WHERE SL='10659-001005'
--select 'boldAPTL20141212',* from [boldAPTL20141212] (nolock) WHERE SL='10659-001005'
--select 'budPMSL_bak_20141219',* from [budPMSL_bak_20141219] (nolock) WHERE SL='10659-001005'
--select 'budPMSL_dupe_badvendor',* from [budPMSL_dupe_badvendor] (nolock) WHERE SL='10659-001005'
--select 'budSLCD_bak_20141219',* from [budSLCD_bak_20141219] (nolock) WHERE SL='10659-001005'
--select 'budSLIT_bak_20141219',* from [budSLIT_bak_20141219] (nolock) WHERE SL='10659-001005'
--select 'budSLIT_bak_20141220',* from [budSLIT_bak_20141220] (nolock) WHERE SL='10659-001005'
--select 'mckbSLIT_11-26-2014',* from [mckbSLIT_11-26-2014] (nolock) WHERE SL='10659-001005'
--select 'vPMDistribution',* from [vPMDistribution] (nolock) WHERE SL='10659-001005'
--select 'vPMSubcontractCO',* from [vPMSubcontractCO] (nolock) WHERE SL='10659-001005'
--select 'vSLClaimHeader',* from [vSLClaimHeader] (nolock) WHERE SL='10659-001005'
--select 'vSLClaimItem',* from [vSLClaimItem] (nolock) WHERE SL='10659-001005'
--select 'vSLClaimItemVariation',* from [vSLClaimItemVariation] (nolock) WHERE SL='10659-001005'
--select 'vSLInExclusions',* from [vSLInExclusions] (nolock) WHERE SL='10659-001005'
--select 'vSLWHHist',* from [vSLWHHist] (nolock) WHERE SL='10659-001005'
--select 'vSLWIHist',* from [vSLWIHist] (nolock) WHERE SL='10659-001005'
--select 'vSLWIInvoices',* from [vSLWIInvoices] (nolock) WHERE SL='10659-001005'
go

*/
USE Viewpoint
go


DISABLE TRIGGER dbo.btPMSSu ON dbo.bPMSS
go
DISABLE TRIGGER dbo.btPMSLu ON dbo.bPMSL
go
DISABLE TRIGGER dbo.btSLCTu ON dbo.bSLCT
go
DISABLE TRIGGER dbo.btSLHDu ON dbo.bSLHD
go

BEGIN TRAN

UPDATE bPMSS SET SL='10659-001001' WHERE SL='10659-001005'
UPDATE bPMSL SET SL='10659-001001' WHERE SL='10659-001005'
UPDATE bSLCT SET SL='10659-001001' WHERE SL='10659-001005'
UPDATE bSLHD SET SL='10659-001001' WHERE SL='10659-001005'

IF @@error<>0
	ROLLBACK TRAN
ELSE
	COMMIT TRAN
go
 

ENABLE TRIGGER dbo.btPMSSu ON dbo.bPMSS
go
ENABLE TRIGGER dbo.btPMSLu ON dbo.bPMSL
go
ENABLE TRIGGER dbo.btSLCTu ON dbo.bSLCT
go
ENABLE TRIGGER dbo.btSLHDu ON dbo.bSLHD
go