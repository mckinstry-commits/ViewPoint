SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Extract craft and class hierarchy template and
	standard data.  This data will be use to report craft and class 
	processing values.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	1/19/08	125224	New
********************************************************************/
CREATE view [dbo].[vrvPRCraftClassHierarchy] as
--** PRTF  Craft Class Template Addons
SELECT
Rectype = 'PRTF'	
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description	
,HeaderGroupTemplate = PRTM.Description  + PRCC.Craft + PRCC.Class	
,HierarchyLevel = 4								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description
,EEOClass = PRCC.EEOClass						
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate	
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = PRTF.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description				--Template Description
,CraftTemplate = PRTF.Template
,CraftClassTemplate = PRTF.Template
,Shift = null
,EarnCode = PRTF.EarnCode					--EarnCode
,Factor = PRTF.Factor						--Factor
,OldRate = PRTF.OldRate						--OldRate
,NewRate = PRTF.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTF (Nolock)
		ON PRCC.PRCo = PRTF.PRCo and PRCC.Craft = PRTF.Craft and PRCC.Class = PRTF.Class
Inner Join PRCT (Nolock)
		ON PRTF.PRCo = PRCT.PRCo and PRTF.Craft = PRCT.Craft and PRTF.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRTF.PRCo = PREC.PRCo and PRTF.EarnCode = PREC.EarnCode
Inner Join PRTM  (Nolock)
	ON PRTF.PRCo = PRTM.PRCo and PRTF.Template= PRTM.Template

--** PRTI  Craft Template Addons
UNION ALL
SELECT
Rectype = 'PRTI'
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description		
,HeaderGroupTemplate = PRTM.Description	+ PRCC.Craft + PRCC.Class															
,HierarchyLevel = 3								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class					
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate	
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  
,Method = PREC.Method
,Template = PRTI.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description					--Template Description
,CraftTemplate = PRTI.Template
,CraftClassTemplate = null
,Shift = null
,EarnCode = PRTI.EDLCode						--Deduction Liability Code
,Factor = PRTI.Factor						--Factor
,OldRate = PRTI.OldRate						--OldRate
,NewRate = PRTI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTI (Nolock)
		ON PRCC.PRCo = PRTI.PRCo and PRCC.Craft = PRTI.Craft
Inner Join PRCT (Nolock)
		ON PRTI.PRCo = PRCT.PRCo and PRTI.Craft = PRCT.Craft and PRTI.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRTI.PRCo = PREC.PRCo and PRTI.EDLCode = PREC.EarnCode
Inner Join PRTM  (Nolock)
	ON PRTI.PRCo = PRTM.PRCo and PRTI.Template= PRTM.Template
Where PRTI.EDLType = 'E'

--** PRCF  Craft Class Addons
UNION ALL
SELECT
Rectype = 'PRCF'
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class  + ISNULL(Cast(e.Description as varchar),'')		
,HeaderGroupTemplate = ISNULL(Cast(e.Description as varchar),'')	+ PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = ISNULL(e.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = e.Description		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = null
,EarnCode = PRCF.EarnCode						--Deduction Liability Code
,Factor = PRCF.Factor						--Factor
,OldRate = PRCF.OldRate						--OldRate
,NewRate = PRCF.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCF (Nolock)
		ON PRCC.PRCo = PRCF.PRCo and PRCC.Craft = PRCF.Craft and PRCC.Class = PRCF.Class
Inner Join PRCM (Nolock)
		ON PRCF.PRCo = PRCM.PRCo and PRCF.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCF.PRCo = PREC.PRCo and PRCF.EarnCode = PREC.EarnCode
left outer join
	(select distinct PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description from PRCT (Nolock)
		Inner Join PRTM (Nolock)
			ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
		group by PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description ) e 
	on PRCC.PRCo = e.PRCo and PRCC.Craft = e.Craft
Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft and PRCT.Template = e.Template


UNION ALL
--** PRCI  Craft Addons
SELECT
Rectype = 'PRCI'
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class + ISNULL(Cast(e.Description as varchar),'')
,HeaderGroupTemplate = ISNULL(Cast(e.Description as varchar),'')	+ PRCC.Craft + PRCC.Class
,HierarchyLevel = 1								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description	
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Description
,Method = PREC.Method
,Template = ISNULL(e.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = e.Description					--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = null
,EarnCode = PRCI.EDLCode						--Deduction Liability Code
,Factor = PRCI.Factor						--Factor
,OldRate = PRCI.OldRate						--OldRate
,NewRate = PRCI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCI (Nolock)
		ON PRCC.PRCo = PRCI.PRCo and PRCC.Craft = PRCI.Craft
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCI.PRCo = PREC.PRCo and PRCI.EDLCode = PREC.EarnCode
left outer join
	(select distinct PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description from PRCT (Nolock)
		Inner Join PRTM (Nolock)
			ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
		group by PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description ) e 
	on PRCC.PRCo = e.PRCo and PRCC.Craft = e.Craft
Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft and PRCT.Template = e.Template
Where PRCI.EDLType = 'E'

--** PRCF  Craft Class Only Addons
UNION ALL
SELECT
Rectype = 'PRCFCC'
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class		
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = null
,OverEffectDate = null
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = 0					--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = null		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = null
,EarnCode = PRCF.EarnCode						--Deduction Liability Code
,Factor = PRCF.Factor						--Factor
,OldRate = PRCF.OldRate						--OldRate
,NewRate = PRCF.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCF (Nolock)
		ON PRCC.PRCo = PRCF.PRCo and PRCC.Craft = PRCF.Craft and PRCC.Class = PRCF.Class
Inner Join PRCM (Nolock)
		ON PRCF.PRCo = PRCM.PRCo and PRCF.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCF.PRCo = PREC.PRCo and PRCF.EarnCode = PREC.EarnCode

UNION ALL
--** PRCI  Craft Only Addons
SELECT
Rectype = 'PRCICC'
,TypeSort = 2		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class
,HierarchyLevel = 1								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description	
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = null
,OverEffectDate = null
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Description
,Method = PREC.Method
,Template = 0					--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = null					--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = null
,EarnCode = PRCI.EDLCode						--Deduction Liability Code
,Factor = PRCI.Factor						--Factor
,OldRate = PRCI.OldRate						--OldRate
,NewRate = PRCI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCI (Nolock)
		ON PRCC.PRCo = PRCI.PRCo and PRCC.Craft = PRCI.Craft
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCI.PRCo = PREC.PRCo and PRCI.EDLCode = PREC.EarnCode
Where PRCI.EDLType = 'E'



--PRTE Craft Class Template Earnings
UNION ALL
SELECT
Rectype = 'PRTE'
,TypeSort = 3		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description	
,HeaderGroupTemplate = PRTM.Description  + PRCC.Craft + PRCC.Class	
,HierarchyLevel = 4								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description
,EEOClass = PRCC.EEOClass						
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate	
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = PRTE.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description				--Template Description
,CraftTemplate = PRTE.Template
,CraftClassTemplate = PRTE.Template
,Shift = PRTE.Shift
,EarnCode = PRTE.EarnCode					--EarnCode
,Factor = NULL						--Factor
,OldRate = PRTE.OldRate						--OldRate
,NewRate = PRTE.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTE (Nolock)
		ON PRCC.PRCo = PRTE.PRCo and PRCC.Craft = PRTE.Craft and PRCC.Class = PRTE.Class
Inner Join PRCT (Nolock)
		ON PRTE.PRCo = PRCT.PRCo and PRTE.Craft = PRCT.Craft and PRTE.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRTE.PRCo = PREC.PRCo and PRTE.EarnCode = PREC.EarnCode
Inner Join PRTM  (Nolock)
	ON PRTE.PRCo = PRTM.PRCo and PRTE.Template= PRTM.Template

--PRCE Craft Class Earnings
UNION ALL
SELECT
Rectype = 'PRCE'	
,TypeSort = 3		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class  + ISNULL(Cast(e.Description as varchar),'')		
,HeaderGroupTemplate = ISNULL(Cast(e.Description as varchar),'')	+ PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,EffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = ISNULL(e.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = e.Description		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = PRCE.Shift
,EarnCode = PRCE.EarnCode						--Deduction Liability Code
,Factor = null								--Factor
,OldRate = PRCE.OldRate						--OldRate
,NewRate = PRCE.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCE (Nolock)
		ON PRCC.PRCo = PRCE.PRCo and PRCC.Craft = PRCE.Craft and PRCC.Class = PRCE.Class
Inner Join PRCM (Nolock)
		ON PRCE.PRCo = PRCM.PRCo and PRCE.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCE.PRCo = PREC.PRCo and PRCE.EarnCode = PREC.EarnCode
left outer join
	(select distinct PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description from PRCT (Nolock)
		Inner Join PRTM (Nolock)
			ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
		group by PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description ) e 
	on PRCC.PRCo = e.PRCo and PRCC.Craft = e.Craft
Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft and PRCT.Template = e.Template


--PRCE Craft Class ONLY Earnings
UNION ALL
SELECT
Rectype = 'PRCECC'	
,TypeSort = 3		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class		
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = null
,OverEffectDate = null
,EarnType = PREC.EarnType
,EarningsDescription = PREC.Description  --Earnings Code Description
,Method = PREC.Method
,Template = 0					--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = null		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = PRCE.Shift
,EarnCode = PRCE.EarnCode						--Deduction Liability Code
,Factor = null								--Factor
,OldRate = PRCE.OldRate						--OldRate
,NewRate = PRCE.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCE (Nolock)
		ON PRCC.PRCo = PRCE.PRCo and PRCC.Craft = PRCE.Craft and PRCC.Class = PRCE.Class
Inner Join PRCM (Nolock)
		ON PRCE.PRCo = PRCM.PRCo and PRCE.Craft = PRCM.Craft
Inner Join PREC (Nolock)
	ON PRCE.PRCo = PREC.PRCo and PRCE.EarnCode = PREC.EarnCode

UNION ALL
--** PRTP  Craft Class Template PayRates
SELECT
Rectype = 'PRTP'	
,TypeSort = 1		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description	
,HeaderGroupTemplate = PRTM.Description  + PRCC.Craft + PRCC.Class	
,HierarchyLevel = 4								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description
,EEOClass = PRCC.EEOClass						
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate	
,OverEffectDate = PRCT.OverEffectDate
,EarnType = NULL --PREC.EarnType
,EarningsDescription = NULL --PREC.Description  --Earnings Code Description
,Method = NULL --PREC.Method
,Template = PRTP.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description				--Template Description
,CraftTemplate = PRTP.Template
,CraftClassTemplate = PRTP.Template
,Shift = PRTP.Shift
,EarnCode = NULL					--EarnCode
,Factor = NULL						--Factor
,OldRate = PRTP.OldRate						--OldRate
,NewRate = PRTP.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTP (Nolock)
		ON PRCC.PRCo = PRTP.PRCo and PRCC.Craft = PRTP.Craft and PRCC.Class = PRTP.Class
Inner Join PRCT (Nolock)
		ON PRTP.PRCo = PRCT.PRCo and PRTP.Craft = PRCT.Craft and PRTP.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRTM  (Nolock)
	ON PRTP.PRCo = PRTM.PRCo and PRTP.Template= PRTM.Template

--**  Craft Class Pay Rates
UNION ALL
SELECT
Rectype = 'PRCP'	
,TypeSort = 1		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class  + ISNULL(Cast(e.Description as varchar),'')		
,HeaderGroupTemplate = ISNULL(Cast(e.Description as varchar),'')	+ PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,EarnType = NULL --PREC.EarnType
,EarningsDescription = NULL --PREC.Description  --Earnings Code Description
,Method = NULL --PREC.Method
,Template = ISNULL(e.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = e.Description		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = PRCP.Shift
,EarnCode = NULL --PRCE.EarnCode						--Deduction Liability Code
,Factor = null								--Factor
,OldRate = PRCP.OldRate						--OldRate
,NewRate = PRCP.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCP (Nolock)
		ON PRCC.PRCo = PRCP.PRCo and PRCC.Craft = PRCP.Craft and PRCC.Class = PRCP.Class
Inner Join PRCM (Nolock)
		ON PRCP.PRCo = PRCM.PRCo and PRCP.Craft = PRCM.Craft
left outer join
	(select distinct PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description from PRCT (Nolock)
		Inner Join PRTM (Nolock)
			ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
		group by PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description ) e 
	on PRCC.PRCo = e.PRCo and PRCC.Craft = e.Craft
Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft and PRCT.Template = e.Template

--**  Craft Class ONLY Pay Rates
UNION ALL
SELECT
Rectype = 'PRCPCC'	
,TypeSort = 1		-- 1=PayRates, 2=Addons,3=Earnings(Var Earn)	
,HeaderGroupName = PRCC.Craft + PRCC.Class		
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2								-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo							
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CTEffectiveDate = null
,OverEffectDate = null
,EarnType = NULL --PREC.EarnType
,EarningsDescription = NULL --PREC.Description  --Earnings Code Description
,Method = NULL --PREC.Method
,Template = 0					--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = NULL		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,Shift = PRCP.Shift
,EarnCode = NULL --PRCE.EarnCode						--Deduction Liability Code
,Factor = null								--Factor
,OldRate = PRCP.OldRate						--OldRate
,NewRate = PRCP.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCP (Nolock)
		ON PRCC.PRCo = PRCP.PRCo and PRCC.Craft = PRCP.Craft and PRCC.Class = PRCP.Class
Inner Join PRCM (Nolock)
		ON PRCP.PRCo = PRCM.PRCo and PRCP.Craft = PRCM.Craft

GO
GRANT SELECT ON  [dbo].[vrvPRCraftClassHierarchy] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCraftClassHierarchy] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCraftClassHierarchy] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCraftClassHierarchy] TO [public]
GO
