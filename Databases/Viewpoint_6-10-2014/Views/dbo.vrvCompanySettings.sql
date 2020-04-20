SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*******
 Created:  GW 11/5/2010
 Modified:  
 Usage:  View selects columns from all modules company tables to create a report that will print
          the interface settings.  By creating record types, it will allow for sorting
          and grouping by module in the report.  This report will be used by VCS consultants
          and customers to verify interface settings after prior to live processing.
*******/  



CREATE view [dbo].[vrvCompanySettings]

as

Select
      hq.HQCo
      ,APRecType = 'AP'
      , ap.APCo as APCompany
      , ap.GLCo as APGLCo
      , apexp.DisplayValue as APGLExpInterfaceLvl
      , appay.DisplayValue as APGLPayInterfaceLvl
      , ap.CMCo as APCMCo
      , apcm.DisplayValue as APCMInterfaceLvl
      , ap.JCCo as APJCCo
      , apjc.DisplayValue as APJCInterfaceLvl
      , ap.INCo as APINCo
      , apin.DisplayValue as APINInterfaceLvl
      , ap.EMCo as APEMCo
      , apem.DisplayValue as APEMInterfaceLvl
      , ARRecType = 'AR'
      , ar.ARCo  as ARCompany
      , ar.GLCo  as ARGLCo
      , arinv.DisplayValue as ARGLInvLvl
      , arpay.DisplayValue as ARGLPayLvl
      , armisc.DisplayValue as GLMiscCashLvl
      , ar.CMCo as ARCMCo
      , arcm.DisplayValue as ARCMInterface
      , ar.JCCo as ARJCCo
      , arjc.DisplayValue as ARJCInterface
      , arfc.DisplayValue as ARFCInterface
      , ar.EMCo as AREMCo
      , arem.DisplayValue as AREMInterface
      , CMRecType = 'CM'
      , cm.CMCo as CMCompany
      , cm.GLCo as CMGLCo
      , cmgl.DisplayValue as CMGLInterface
      , EMRecType = 'EM'
      , em.EMCo as EMCompany
      , em.GLCo as EMGLCo
      , emad.DisplayValue as EMAdjGLInterface  
      , emus.DisplayValue as EMUseGLInterface       
      , emma.DisplayValue as EMMatGLInterface 
      , INRecType = 'IN'      
      , inv.INCo as INCompany
      , inv.GLCo as INGLCo
      , inad.DisplayValue as INAdjInterfaceLvl
      , intr.DisplayValue as INTrnsfrInterfaceLvl
      , inpd.DisplayValue as INProdInterfaceLvl
      , inmoj.DisplayValue as INJCMOInterfaceLvl
      , inmog.DisplayValue as INGLMOInterfaceLvl
      , JCRecType = 'JC'      
      , jc.JCCo as JCCompany
      , jc.INCo as JCINCo
      , jc.GLCo as JCGLCo
      , jcco.DisplayValue as JCCostInterfaceLvl
      , jcrv.DisplayValue as JCRevInterfaceLvl
      , jccl.DisplayValue as JCCloseInterfaceLvl
      , jcmt.DisplayValue as JCMatInterfaceLvl
      , MSRecType = 'MS'      
      , ms.MSCo as MSCompany
      , ms.GLCo as MSGLCo
      , ms.ARCo as MSARCo
      , msti.DisplayValue as MSGLTicLvl
      , msem.DisplayValue as MSEMInterfaceLvl
      , msin.DisplayValue as MSINInterfaceLvl
      , msjc.DisplayValue as MSJCInterfaceLvl 
      , msar.DisplayValue as MSARInterfaceLvl  
      , msinv.DisplayValue as MSGLInvInterfaceLvl 
      , msinp.DisplayValue as MSINProdInvInterfaceLvl 
      , PORecType = 'PO'      
      , po.POCo as POCompany
      , pore.DisplayValue as POGLRecExpInterfacelvl
      , poem.DisplayValue as PORecEMInterfacelvl
      , poin.DisplayValue as PORecINInterfacelvl
      , pojc.DisplayValue as PORecJCInterfacelvl
      , PRRecType = 'PR'      
      , pr.PRCo as PRCompany
      , pr.GLCo as PRGLCo
      , pr.CMCo as PRCMCo
      , pr.APCo as PRAPCo
      , pr.JCCo as PRJCCo
      , pr.EMCo as PREMCo
      , pr.GLInterface
      , pr.JCInterface
      , pr.EMInterface

      
          
      
      FROM bHQCO hq
      LEFT JOIN APCO ap on hq.HQCo = ap.APCo
      LEFT JOIN ARCO ar on hq.HQCo = ar.ARCo
      LEFT JOIN CMCO cm on hq.HQCo = cm.CMCo
      LEFT JOIN EMCO em on hq.HQCo = em.EMCo
      LEFT JOIN INCO inv on hq.HQCo = inv.INCo 
      LEFT JOIN JCCO jc on hq.HQCo = jc.JCCo 
      LEFT JOIN MSCO ms on hq.HQCo = ms.MSCo    
      LEFT JOIN POCO po on hq.HQCo = po.POCo
      LEFT JOIN PRCO pr on hq.HQCo = pr.PRCo
      
      LEFT JOIN vDDCI apexp ON apexp.ComboType = 'GLExpIntfaceLvl'
                              AND apexp.DatabaseValue = ap.GLExpInterfaceLvl
      LEFT JOIN vDDCI appay ON appay.ComboType = 'GLPayInterfaceLvl'
                              AND appay.DatabaseValue = ap.GLPayInterfaceLvl
      LEFT JOIN vDDCI apcm ON apcm.ComboType = 'CMInterfaceLvl'
                              AND apcm.DatabaseValue = ap.CMInterfaceLvl                        
      LEFT JOIN vDDCI apjc ON apjc.ComboType = 'JCInterfaceLvl'
                              AND apjc.DatabaseValue = ap.JCInterfaceLvl      
      LEFT JOIN vDDCI apin ON apin.ComboType = 'INInterfaceLvl'
                              AND apin.DatabaseValue = ap.INInterfaceLvl      
      LEFT JOIN vDDCI apem ON apem.ComboType = 'EMInterfaceLvl'
                              AND apem.DatabaseValue = ap.EMInterfaceLvl
      LEFT JOIN vDDCI arinv ON arinv.ComboType = 'ARInterfaceGLOpt'
                              AND arinv.DatabaseValue = ar.GLInvLev
      LEFT JOIN vDDCI arpay ON arpay.ComboType = 'ARInterfaceGLOpt'
                              AND arpay.DatabaseValue = ar.GLPayLev
      LEFT JOIN vDDCI armisc ON armisc.ComboType = 'ARInterfaceGLOpt'
                              AND armisc.DatabaseValue = ar.GLMiscCashLev
      LEFT JOIN vDDCI arcm ON arcm.ComboType = 'CMInterfaceLvl'
                              AND arcm.DatabaseValue = ar.CMInterface                     
      LEFT JOIN vDDCI arjc ON arjc.ComboType = 'JCInterfaceLvl'
                              AND arjc.DatabaseValue = ar.JCInterface   
      LEFT JOIN vDDCI arfc ON arfc.ComboType = 'ARFinChgOpt'
                              AND arfc.DatabaseValue = ar.FCLevel 
      LEFT JOIN vDDCI arem ON arem.ComboType = 'EMInterfaceLvl'
                              AND arem.DatabaseValue = ar.EMInterface                       
      LEFT JOIN vDDCI cmgl ON cmgl.ComboType = 'CMGLInterFaceLevel'
                              AND cmgl.DatabaseValue = cm.GLInterfaceLvl
      LEFT JOIN vDDCI emad ON emad.ComboType = 'EMAdjstGLLvl'
                              AND emad.DatabaseValue = em.AdjstGLLvl
      LEFT JOIN vDDCI emus ON emus.ComboType = 'EMUseGLLvl'
                              AND emus.DatabaseValue = em.UseGLLvl
      LEFT JOIN vDDCI emma ON emma.ComboType = 'EMMatlGLLvl'
                              AND emma.DatabaseValue = em.MatlGLLvl 
      LEFT JOIN vDDCI inad ON inad.ComboType = 'INCOInterfaceLevel'
                              AND inad.DatabaseValue = inv.GLAdjInterfaceLvl  
      LEFT JOIN vDDCI inpd ON inpd.ComboType = 'INCOInterfaceLevel'
                              AND inpd.DatabaseValue = inv.GLProdInterfaceLvl
      LEFT JOIN vDDCI intr ON intr.ComboType = 'INCOInterfaceLevel'
                              AND intr.DatabaseValue = inv.GLTrnsfrInterfaceLvl
      LEFT JOIN vDDCI inmoj ON inmoj.ComboType = 'INCOInterfaceLevel'
                              AND inmoj.DatabaseValue = inv.JCMOInterfaceLvl
      LEFT JOIN vDDCI inmog ON inmog.ComboType = 'INCOInterfaceLevel'
                              AND inmog.DatabaseValue = inv.GLMOInterfaceLvl  
      LEFT JOIN vDDCI jcco ON jcco.ComboType = 'JCGLCostLevel'
                              AND jcco.DatabaseValue = jc.GLCostLevel  
      LEFT JOIN vDDCI jcrv ON jcrv.ComboType = 'JCGLRevenueLevel'
                              AND jcrv.DatabaseValue = jc.GLRevLevel                          
      LEFT JOIN vDDCI jccl ON jccl.ComboType = 'JCGLCloseLevel'
                              AND jccl.DatabaseValue = jc.GLCloseLevel                                   
      LEFT JOIN vDDCI jcmt ON jcmt.ComboType = 'JCGLMaterialLevel'
                              AND jcmt.DatabaseValue = jc.GLMaterialLevel                             
      LEFT JOIN vDDCI msti ON msti.ComboType = 'MSCoInterfaceLevel'
                              AND msti.DatabaseValue = ms.GLTicLvl                              
      LEFT JOIN vDDCI msem ON msem.ComboType = 'MSCoInterfaceLevel'
                              AND msem.DatabaseValue = ms.EMInterfaceLvl                        
      LEFT JOIN vDDCI msin ON msin.ComboType = 'MSCoInterfaceLevel'
                              AND msin.DatabaseValue = ms.INInterfaceLvl 
	  LEFT JOIN vDDCI msjc ON msjc.ComboType = 'MSCoInterfaceLevel'
                              AND msjc.DatabaseValue = ms.JCInterfaceLvl
      LEFT JOIN vDDCI msar ON msar.ComboType = 'MSCoARInterfaceLvl'
                              AND msar.DatabaseValue = ms.ARInterfaceLvl
      LEFT JOIN vDDCI msinv ON msinv.ComboType = 'MSCoARInterfaceLvl'
                              AND msinv.DatabaseValue = ms.GLInvLvl
      LEFT JOIN vDDCI msinp ON msinp.ComboType = 'MSCoARInterfaceLvl'
                              AND msinp.DatabaseValue = ms.INProdInterfaceLvl
      LEFT JOIN vDDCI pore ON pore.ComboType = 'GLExpIntfaceLvl'
                              AND pore.DatabaseValue = po.GLRecExpInterfacelvl                         
      LEFT JOIN vDDCI poin ON poin.ComboType = 'INInterfaceLvl'
                              AND poin.DatabaseValue = po.RecINInterfacelvl                               
      LEFT JOIN vDDCI poem ON poem.ComboType = 'EMInterfaceLvl'
                              AND poem.DatabaseValue = po.RecEMInterfacelvl                               
      LEFT JOIN vDDCI pojc ON pojc.ComboType = 'JCInterfaceLvl'
                              AND pojc.DatabaseValue = po.RecJCInterfacelvl                              




GO
GRANT SELECT ON  [dbo].[vrvCompanySettings] TO [public]
GRANT INSERT ON  [dbo].[vrvCompanySettings] TO [public]
GRANT DELETE ON  [dbo].[vrvCompanySettings] TO [public]
GRANT UPDATE ON  [dbo].[vrvCompanySettings] TO [public]
GRANT SELECT ON  [dbo].[vrvCompanySettings] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvCompanySettings] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvCompanySettings] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvCompanySettings] TO [Viewpoint]
GO
