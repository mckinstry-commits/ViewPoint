SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[vrvJCRatesUnbilledAnalysis]

as

/********************************************************************
 * Created By:	Sales - Initial version for customer 
 *				report T&M Unbilled Analysis
 * Modfied By:  TFS 1669 HH 1/6/11 - No modification, created in VPDev640 
 *				for customer report T&M Unbilled Analysis to 
 *				become Standard report: JC Unbilled Analysis 
 *
 *	Used on JC Unbilled Analysis report.
 *
 *********************************************************************/

	Select  Type='',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase,
		JCCD.CostType, JCCD.PostedDate, JCCD.ActualDate, JCCD.JCTransType, JCCD.Source, JCCD.Description, JCCD.GLCo, 
		JCCD.ActualHours, JCCD.ActualUnits, JCCD.ActualCost, JCCD.PRCo, JCCD.Employee, JCCD.Craft, JCCD.Class,
		JCCD.EarnFactor, JCCD.VendorGroup, JCCD.Vendor, JCCD.APCo, JCCD.APRef, JCCD.PO, JCCD.MatlGroup, JCCD.Material, JCCD.INCo, JCCD.JBBillStatus, 
		JCCD.EMCo, JCCD.EMEquip, JBIJ.Amt, JBIJ.UnitPrice, BillStatus=isnull(JCCD.JBBillStatus,0),
		JBRateOption=right(dbo.vf_rptJBLaborRate (JCCD.JCCo,JCCM.JBTemplate,
                (case when x.ClassMatch='L' then x.LaborCategory else 
				(case when y.CraftMatch='C' then y.LaborCategory else 
                (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end) end), JCCD.PRCo, JCCD.Employee, 
				JCCD.Craft, JCCD.Class, JCCD.Shift, JCCD.EarnType, JCCD.EarnFactor, JCCD.ActualDate, JBTM.LaborEffectiveDate),1), 
		JBLaborRate=convert(numeric (8,2), left(dbo.vf_rptJBLaborRate (JCCD.JCCo,JCCM.JBTemplate, 
                (case when x.ClassMatch='L' then x.LaborCategory else 
				(case when y.CraftMatch='C' then y.LaborCategory else 
                (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end) end), JCCD.PRCo, JCCD.Employee, 
				JCCD.Craft, JCCD.Class, JCCD.Shift, JCCD.EarnType, JCCD.EarnFactor, JCCD.ActualDate, JBTM.LaborEffectiveDate),10)), 
		JCCM.Contract, JCCM.JBTemplate, JBTM.LaborEffectiveDate, 
		LaborCategory=(case when x.ClassMatch='L' then x.LaborCategory else 
                      (case when y.CraftMatch='C' then y.LaborCategory else 
                      (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end) end),
 		--start of Equipment Rate Option function
		EquipRateOption=right(dbo.vf_rptJBEquipRate (JCCD.JCCo,JCCM.JBTemplate,EMEM.Category, JCCD.EMCo, JCCD.EMGroup, 
				JCCD.EMEquip, JCCD.EMRevCode, JCCD.ActualDate, JBTM.EquipEffectiveDate),1), 
	    --end of Equipment Rate Option function

	    --start of Equipment Rate function
		JBEquipRate=convert(numeric (8,2), left(dbo.vf_rptJBEquipRate (JCCD.JCCo,JCCM.JBTemplate,EMEM.Category, JCCD.EMCo, JCCD.EMGroup, 
				JCCD.EMEquip, JCCD.EMRevCode, JCCD.ActualDate, JBTM.EquipEffectiveDate),10)),
	     --end of Equipment Rate  function 

         --start of Material Rate Option function
         MatlRateOption=right(dbo.vf_rptJBMatlRate(JCCD.JCCo, JCCM.JBTemplate,
	           --start of template sequence function
		         dbo.vf_rptJBGetTempSeq(
                /*@co*/JCCD.JCCo, 
                /*@template*/JCCM.JBTemplate, 
			    /*@category*/
				      case when (JCCD.JCTransType= 'PR' and JCCT.JBCostTypeCategory in ('L','B') and (JBTM.LaborCatYN = 'Y' or JBTM.LaborRateOpt='R')) or
          					(JCCD.JCTransType = 'PR' and JCCT.JBCostTypeCategory ='E' and (JBTM.EquipCatYN = 'Y' or JBTM.EquipRateOpt in('T','R')) or
          					((JCCD.JCTransType = 'MT' or JCCD.JCTransType = 'IN'or JCCD.JCTransType = 'MS') and JBTM.MatlCatYN = 'Y') or
          					(JCCD.JCTransType = 'EM' and(JBTM.EquipRateOpt in('T','R') or JBTM.EquipCatYN = 'Y')))
				      then (case when JCCD.Source= 'EM' or (JCCD.Source = 'PR' and JCCT.JBCostTypeCategory = 'E') or 
					       (JCCD.EMEquip is not null and JCCD.EMCo is not null and JCCT.JBCostTypeCategory = 'E')
					        then EMEM.Category
					        else
						        case when JCCD.MatlGroup is not null and JCCD.Material is not null and JCCT.JBCostTypeCategory='M' 
						        then HQMT.Category 
						        else (case when x.ClassMatch='L' then x.LaborCategory 
							          else (case when y.CraftMatch='C' then y.LaborCategory else 
                                            (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end)
							          end)
						        end
					        end)
				      else null end,
			    /*@jbidsource*/(case when JCCD.Source = 'JC MatUse'  then 'IN' else left(JCCD.Source,2) end),
   			    /*@earntype*/JCCD.EarnType,
                /*@liabtype*/JCCD.LiabilityType, 
                /*@phasegrp*/JCCD.PhaseGroup,
   			    /*@jcctype*/JCCD.CostType, 
			    /*@jctranstype*/(case when JCCD.JCTransType='CA' then 'JC' else 
                      (case when JCCD.JCTransType='MI' then 'IN' else JCCD.JCTransType end) end)),
	           --end of template sequence function
            /*@category*/case when (JCCD.JCTransType= 'PR' and JCCT.JBCostTypeCategory in ('L','B') and (JBTM.LaborCatYN = 'Y' or JBTM.LaborRateOpt='R')) or
          					(JCCD.JCTransType = 'PR' and JCCT.JBCostTypeCategory ='E' and (JBTM.EquipCatYN = 'Y' or JBTM.EquipRateOpt in('T','R')) or
          					((JCCD.JCTransType = 'MT' or JCCD.JCTransType = 'IN'or JCCD.JCTransType = 'MS') and JBTM.MatlCatYN = 'Y') or
          					(JCCD.JCTransType = 'EM' and(JBTM.EquipRateOpt in('T','R') or JBTM.EquipCatYN = 'Y')))
				then (case when JCCD.Source= 'EM' or (JCCD.Source = 'PR' and JCCT.JBCostTypeCategory = 'E') or 
					(JCCD.EMEquip is not null and JCCD.EMCo is not null and JCCT.JBCostTypeCategory = 'E')
					then EMEM.Category
					else
						case when JCCD.MatlGroup is not null and JCCD.Material is not null and JCCT.JBCostTypeCategory='M' 
						then HQMT.Category 
						else (	case when x.ClassMatch='L' then x.LaborCategory 
							else (case when y.CraftMatch='C' then y.LaborCategory else 
                                  (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end) 
							end)
						end
					end)
				else null end,
            /*@jbidsource*/(case when JCCD.Source = 'JC MatUse'  then 'IN' else left(JCCD.Source,2) end),
            /*@phasegrp*/JCCD.PhaseGroup,
            /*@jcctype*/JCCD.CostType, 
            /*@jctranstype*/(case when JCCD.JCTransType='CA' then 'JC' else 
               (case when JCCD.JCTransType='MI' then 'IN' else JCCD.JCTransType end) end), 
   	        /*@jccdunitcost*/JCCD.ActualUnitCost, 
            /*@jccdecm*/JCCD.PerECM, 
   	        /*@matlgroup bGroup*/JCCD.MatlGroup, 
            /*@material bMatl*/JCCD.Material, 
            /*@inco bCompany*/JCCD.INCo, 
            /*@loc bLoc*/JCCD.Loc,
   	        /*@jcum bUM*/JCCD.UM, 
            /*@actualdate bDate*/JCCD.ActualDate, 
            /*@effectivedate bDate*/JBTM.MatlEffectiveDate),1),
         --end of Material Rate Option Function


         --start of Material Rate Function
            JBMatlRate=convert(numeric (8,2), left(dbo.vf_rptJBMatlRate(JCCD.JCCo, JCCM.JBTemplate,
	         --start of template sequence function
		         dbo.vf_rptJBGetTempSeq(
            /*@co*/JCCD.JCCo, 
            /*@template*/JCCM.JBTemplate, 
			/*@category*/ 		
				      case when (JCCD.JCTransType= 'PR' and JCCT.JBCostTypeCategory in ('L','B') and (JBTM.LaborCatYN = 'Y' or JBTM.LaborRateOpt='R')) or
          					(JCCD.JCTransType = 'PR' and JCCT.JBCostTypeCategory ='E' and (JBTM.EquipCatYN = 'Y' or JBTM.EquipRateOpt in('T','R')) or
          					((JCCD.JCTransType = 'MT' or JCCD.JCTransType = 'IN'or JCCD.JCTransType = 'MS') and JBTM.MatlCatYN = 'Y') or
          					(JCCD.JCTransType = 'EM' and(JBTM.EquipRateOpt in('T','R') or JBTM.EquipCatYN = 'Y')))
				      then (case when JCCD.Source= 'EM' or (JCCD.Source = 'PR' and JCCT.JBCostTypeCategory = 'E') or 
					       (JCCD.EMEquip is not null and JCCD.EMCo is not null and JCCT.JBCostTypeCategory = 'E')
					        then EMEM.Category
					        else
						        case when JCCD.MatlGroup is not null and JCCD.Material is not null and JCCT.JBCostTypeCategory='M' 
						        then HQMT.Category 
						        else (case when x.ClassMatch='L' then x.LaborCategory 
							          else (case when y.CraftMatch='C' then y.LaborCategory else 
                                            (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end)
							          end)
						        end
					        end)
				      else null end,
			/*@jbidsource*/(case when JCCD.Source = 'JC MatUse'  then 'IN' else left(JCCD.Source,2) end),
   			/*@earntype*/JCCD.EarnType, 
            /*@liabtype*/JCCD.LiabilityType, 
            /*@phasegrp*/JCCD.PhaseGroup,
   			/*@jcctype*/JCCD.CostType, 
			/*@jctranstype*/(case when JCCD.JCTransType='CA' then 'JC' else 
                   (case when JCCD.JCTransType='MI' then 'IN' else JCCD.JCTransType end) end)),
	     --end of template sequence function
            /*@category*/case when (JCCD.JCTransType= 'PR' and JCCT.JBCostTypeCategory in ('L','B') and (JBTM.LaborCatYN = 'Y' or JBTM.LaborRateOpt='R')) or
          					(JCCD.JCTransType = 'PR' and JCCT.JBCostTypeCategory ='E' and (JBTM.EquipCatYN = 'Y' or JBTM.EquipRateOpt in('T','R')) or
          					((JCCD.JCTransType = 'MT' or JCCD.JCTransType = 'IN'or JCCD.JCTransType = 'MS') and JBTM.MatlCatYN = 'Y') or
          					(JCCD.JCTransType = 'EM' and(JBTM.EquipRateOpt in('T','R') or JBTM.EquipCatYN = 'Y')))
				then (case when JCCD.Source= 'EM' or (JCCD.Source = 'PR' and JCCT.JBCostTypeCategory = 'E') or 
					(JCCD.EMEquip is not null and JCCD.EMCo is not null and JCCT.JBCostTypeCategory = 'E')
					then EMEM.Category
					else
						case when JCCD.MatlGroup is not null and JCCD.Material is not null and JCCT.JBCostTypeCategory='M' 
						then HQMT.Category 
						else (	case when x.ClassMatch='L' then x.LaborCategory 
							else (case when y.CraftMatch='C' then y.LaborCategory else 
                                     (case when y1.ClassMatch='S' then y1.LaborCategory else z.LaborCategory end) end)
							end)
						end
					end)
				else null end,
            /*@jbidsource*/(case when JCCD.Source = 'JC MatUse'  then 'IN' else left(JCCD.Source,2) end),
            /*@phasegrp*/JCCD.PhaseGroup,
            /*@jcctype*/JCCD.CostType, 
            /*@jctranstype*/(case when JCCD.JCTransType='CA' then 'JC' else 
                   (case when JCCD.JCTransType='MI' then 'IN' else JCCD.JCTransType end) end), 
   	        /*@jccdunitcost*/JCCD.ActualUnitCost, 
            /*@jccdecm*/JCCD.PerECM, 
   	        /*@matlgroup bGroup*/JCCD.MatlGroup, 
            /*@material bMatl*/JCCD.Material, 
            /*@inco bCompany*/JCCD.INCo, 
            /*@loc bLoc*/JCCD.Loc,
   	        /*@jcum bUM*/JCCD.UM, 
            /*@actualdate bDate*/JCCD.ActualDate, 
            /*@effectivedate bDate*/JBTM.MatlEffectiveDate),10)),
         -- end of Material Rate Function

        ContDesc=JCCM.Description,/* added the JCCDDetlDesc view starting here*/
	    DetlDesc= Case when JCCD.Source = 'JC CostAdj' and JCCD.JCTransType ='JC' then 
                             (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end)
                          when JCCD.JCTransType='AP' then  
    			  (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) +  
    			  (case when IsNull(JCCD.APCo,0) <> 0 then ('/ APCo: '+ convert (varchar(3),JCCD.APCo)) else '' end) +
    			  (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) +
    			  (case when IsNull(JCCD.APTrans,0) <> 0  then  (' / TR# '+  convert (varchar(7),JCCD.APTrans) +'/'+ convert (varchar(5), ISNULL(JCCD.APLine,' '))) else ''   end) +
    			  (case when IsNull(JCCD.APRef ,' ') <>' ' then  (' / Ref#  '+ JCCD.APRef ) else '' end)+
                             (case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ JCCD.Material + '-'+ HQMT.Description) else '' end) +
    			  (case when IsNull(JCCD.PO,' ') <>' ' then ('/ PO#-Line ' + JCCD.PO+'-'+convert (varchar(5),IsNull(JCCD.POItem,0)))else '' end)+
    			  (case when IsNull(JCCD.SL,' ') <> ' ' then ('/ SL#-Item ' + JCCD.SL+'-'+convert (varchar(5),IsNull(JCCD.SLItem,0)))else '' end)
    			 
    		       when JCCD.JCTransType ='CO' then 
                             (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) + 
           		  (case when IsNull(JCCD.ACO,' ') <> ' ' then ('ACO '+ JCCD.ACO +' /ACOItem '+JCCD.ACOItem+ IsNull(JCOI.Description,isNull(JCOH.Description,' '))) else '' end) 
                           
    		       when JCCD.JCTransType='EM' then 
                            (Case when IsNull(JCCD.EMEquip,' ')<> ' ' then ('Equip# '+ JCCD.EMEquip + '-'+ IsNull(EMEM.Description,' ') + '/'+ IsNull(JCCD.Description,' ')+'/ ') else '' end) +
   			 (Case when IsNull(JCCD.EMTrans,0) <> 0 then convert(varchar(5),JCCD.EMTrans)else '' end) +
    			 (Case when IsNull(JCCD.EMRevCode,' ')<> ' ' then '/ Rev Code: '+ JCCD.EMRevCode + IsNull(EMRC.Description,' ') else '' end)+
                            (Case when IsNull(JCCD.Employee,0)<>0 then ('/  Emp: '+ convert(varchar(6),JCCD.Employee)+'/'+IsNull(PREH.LastName,' ') +' '+IsNull(PREH.Suffix,' ')+', '+IsNull(PREH.FirstName,' ') +' '+IsNull(PREH.MidName,' ')) else '' end )
    		      
   		       when JCCD.JCTransType ='IC' then 
                             (case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) + 
           		  (case when IsNull(JCCD.SrcJCCo,0) <> 0 then (' /Src JCCo: '+ convert (varchar(3),JCCD.SrcJCCo)) else '' end)  
  
   		       when JCCD.JCTransType='IN' then 
                           (Case when IsNull(JCCD.Material,' ') <> ' ' then('Mat# '+ JCCD.Material+'  '+ IsNull(HQMT.Description,' ') +'-'+IsNull(JCCD.Description,' ')) else '' end)+ 
    			(case when IsNull(JCCD.Loc,' ')<>' ' then (' /Loc '+ JCCD.Loc +' '+IsNull(INLM.Description,' ')) else '' end )
   		        
    		       when JCCD.JCTransType ='MO' then 
   			(Case when IsNull(JCCD.Description,' ') <> ' ' then JCCD.Description else '' end) +
    			(case when IsNull(JCCD.MO,' ') <>' ' then ( 'MO# '+ IsNull(JCCD.MO,' ')+' /MOItem '+ convert (varchar(5),JCCD.MOItem)+' /Mat '+JCCD.Material+' '+HQMT.Description) else '' end)
                              
    		       when JCCD.JCTransType='MS' then 
    			(case when IsNull(JCCD.Material,' ') <>' ' then ('Mat '+JCCD.Material+'  '+IsNull(HQMT.Description,' ')+' / '+convert (varchar(7),IsNull(JCCD.MSTrans,0))) else '' end) +
                           (case when IsNull(JCCD.Loc,' ')<>' ' then ('Loc '+JCCD.Loc +' '+INLM.Description) else '' end)+
   			(Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else '' end) 
                       	
    		       when JCCD.JCTransType='MI' then 
                           (Case when IsNull(JCCD.Material,' ')<>' ' then ('Mat# '+ JCCD.Material +'-'+ IsNull(HQMT.Description,' ')+' / ' +IsNull(JCCD.Description,'')) else'' end)
    		      	
    		       when JCCD.JCTransType='PO' then 
    			(case when IsNull(JCCD.PO,' ')<>' ' then ('PO#-'+ JCCD.PO +' /POItem '+ convert (varchar(5),IsNull(JCCD.POItem,0))+IsNull(POIT.Description,IsNull(POHD.Description,'')) + '/'+' Desc: '+ IsNull(JCCD.Description,''))else''end)+
                           (case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) +
    			(case when IsNull(JCCD.Material,' ') <> ' ' then (' / Matl: '+ JCCD.Material + '-'+ HQMT.Description) else '' end) 
                           
    		       when JCCD.JCTransType= 'PR' then  
   			(Case when IsNull(JCCD.Description,' ')<>' ' then JCCD.Description else '' end) +
    			(case when IsNull(JCCD.Craft,' ') <>' ' then ('Craft: ' +JCCD.Craft+ IsNull(PRCM.Description,' ')+'/'+IsNull(JCCD.Class,' ')+IsNull(PRCC.Description,'')) else '' end) +
    			(case when IsNull(JCCD.Employee,0) <> 0 then ('  Emp: '+ convert (varchar(6),IsNull(JCCD.Employee,0))+'/'+IsNull(PREH.LastName,' ') +' '+IsNull(PREH.Suffix,' ')+', '+IsNull(PREH.FirstName,' ') +' '+IsNull(PREH.MidName,' ') ) else '' end)+
   			(case when IsNull(JCCD.Crew,' ')<> ' ' then (JCCD.Crew + IsNull(PRCR.Description,' ')) else '' end) + 			
   			(case when IsNull(JCCD.EMEquip,' ') <> ' ' then (JCCD.EMEquip +'/'+ IsNull(EMEM.Description,' ') +'/'+ IsNull(JCCD.EMRevCode,' ')) else '' end) +
   			(case when IsNull(JCCD.EarnType,0)<>0 then (convert (varchar(4),JCCD.EarnType)+' ' +IsNull(HQET.Description,''))else '' end)+
   			(case when IsNull(JCCD.LiabilityType,0)<> 0 then (convert (varchar(4),JCCD.LiabilityType)+' ' +IsNull(HQLT.Description,' ')) else''end)
   
    		       when JCCD.JCTransType='SL' then 
    			(case when IsNull(JCCD.SL,' ') <>' ' then ('Sub#: ' + JCCD.SL + ' '+IsNull(SLIT.Description,IsNull(SLHD.Description,''))  +' SLItem: '+convert (varchar(5),IsNull(JCCD.SLItem,0))+ '/'+IsNull(JCCD.Description,' ')) else '' end)+
   			(case when IsNull(JCCD.Vendor,0) <> 0 then ('/ '+ convert (varchar(6),IsNull(JCCD.Vendor,0))+ '-'+ left(IsNull(APVM.Name,' '),20)) else '' end) 
                      
    		       when JCCD.JCTransType in ('CV','IC','JC','PF','PE','AR','RU')  then 
   			(Case when IsNull(JCCD.Description,' ')<> ' ' then JCCD.Description else 'No Desc Entered' end)
   
    		    else  'JCTransType/Source: '+ JCCD.JCTransType+ '/' + JCCD.Source end ,
	UniqueAttchID=null,
	AttachmentID=null,AttachDescription=null,DocName=null, ThreshAmt=JCCD.ActualCost
    from dbo.JCCD with(nolock)
   
   left outer join dbo.APVM with(nolock) on JCCD.VendorGroup = APVM.VendorGroup and JCCD.Vendor = APVM.Vendor
   left outer join dbo.EMEM with(nolock) on JCCD.EMCo = EMEM.EMCo and JCCD.EMEquip = EMEM.Equipment
   left outer join dbo.HQMT with(nolock) on JCCD.MatlGroup = HQMT.MatlGroup and JCCD.Material = HQMT.Material
   left outer join dbo.PREH with(nolock) on JCCD.PRCo = PREH.PRCo and JCCD.Employee = PREH.Employee
   left outer join dbo.JCOH with(nolock) on JCCD.JCCo = JCOH.JCCo and JCCD.Job = JCOH.Job and JCCD.ACO = JCOH.ACO
   left outer join dbo.JCOI with(nolock) on JCCD.JCCo = JCOI.JCCo and JCCD.Job = JCOI.Job and JCCD.ACO = JCOI.ACO and JCCD.ACOItem = JCOI.ACOItem
   left outer join dbo.EMRC with(nolock) on JCCD.EMGroup = EMRC.EMGroup and JCCD.EMRevCode = EMRC.RevCode
   left outer join dbo.INLM with(nolock) on JCCD.INCo = INLM.INCo and JCCD.Loc = INLM.Loc
   left outer join dbo.POHD with(nolock) on JCCD.APCo = POHD.POCo and JCCD.PO = POHD.PO
   left outer join dbo.POIT with(nolock) on JCCD.APCo = POIT.POCo and JCCD.PO = POIT.PO and JCCD.POItem = POIT.POItem
   left outer join dbo.PRCM with(nolock) on JCCD.PRCo = PRCM.PRCo and JCCD.Craft = PRCM.Craft
   left outer join dbo.PRCC with(nolock) on JCCD.PRCo = PRCC.PRCo and JCCD.Craft = PRCC.Craft and JCCD.Class = PRCC.Class
   left outer join dbo.PRCR with(nolock) on JCCD.PRCo = PRCR.PRCo and JCCD.Crew = PRCR.Crew
   left outer join dbo.HQET with(nolock) on JCCD.EarnType =HQET.EarnType
   left outer join dbo.HQLT with(nolock) on JCCD.LiabilityType = HQLT.LiabType
   left outer join dbo.SLHD with(nolock) on JCCD.APCo = SLHD.SLCo and JCCD.SL = SLHD.SL
   left outer join dbo.SLIT with(nolock) on JCCD.APCo = SLIT.SLCo and JCCD.SL = SLIT.SL and JCCD.SLItem = SLIT.SLItem
   join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job--to link to JCCM
   join JCCM with(nolock) on JCJM.JCCo=JCCM.JCCo and JCJM.Contract=JCCM.Contract--gets JB Template
   join JBTM with(nolock) on JCCM.JCCo=JBTM.JBCo and JCCM.JBTemplate=JBTM.Template --to get labor rate effective date
   left outer join dbo.JCCT with(nolock) on JCCD.PhaseGroup=JCCT.PhaseGroup and JCCD.CostType=JCCT.CostType
   Left outer join dbo.JBIJ with(nolock) on JCCD.JCCo=JBIJ.JBCo and JCCD.Mth=JBIJ.JCMonth and JCCD.CostTrans=JBIJ.JCTrans



		/*Determines Labor Category from JBLX*/

		/*************** Start of JBLX Select Statement ***************/
		--Restrict by Craft and Class in Labor Category setup
		left join (select ClassMatch='L', JBCo, LaborCategory, Craft, Class from JBLX with(nolock)) as x 
			on JCCD.JCCo=x.JBCo and JCCD.Craft=x.Craft and JCCD.Class=x.Class

		--Restrict by Craft, not class in Labor Category setup
		left join (select CraftMatch='C', JBCo, LaborCategory, Craft, Class from JBLX with(nolock) where RestrictByClass='N') as y
			on JCCD.JCCo=y.JBCo and JCCD.Craft=y.Craft

        --Restrict by Class, not craft in Labor Category setup
		left join (select ClassMatch='S', JBCo, LaborCategory, Craft, Class from JBLX where RestrictByCraft='N'
					and RestrictByClass='Y') as y1
			on JCCD.JCCo=y1.JBCo and JCCD.Class=y1.Class  
         
		--Doesn't restrict by Craft or Class in Labor Category setup
		left join (select NonMatch='N', JBCo, LaborCategory, Craft, Class from JBLX with(nolock) where RestrictByCraft='N' and RestrictByClass='N') as z
			on JCCD.JCCo=z.JBCo and JCCD.Craft is null
		/*************** End of JBLX Select Statement ***************/


  Union all
   
  select distinct 'AP',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCCD.JCTransType,Source,
	Description=null, GLCo=null,ActualHours=null,ActualUnits=null,ActualCost=null,PRCo=null,Employee=null,
  Craft=null,Class=null,EarnFactor=null,VendorGroup=null,Vendor=null,APCo=null,APRef=null,PO=null, MatlGroup=null,Material=null,INCo=null,JCCD.JBBillStatus,
  EMCo=null,EMEquip=null,Amt=null,UnitPrice=null,BillStatus=null,JBRateOption=null,JBLaborRate=null,
  JCJM.Contract, JBTemplate=null,LaborEffecitveDate=null,LaborCategory=null,EquipRateOption=null,JBEquipRate=null,MatlRateOption=null,JBMatlRate=null,
ContDesc=null,DetlDesc=null, APTH.UniqueAttchID,
  HQAI.AttachmentID,HQAT.Description,HQAT.DocName, ThreshAmt=JCCD.ActualCost
  from JCCD
  Join HQAI with (nolock) on JCCD.APCo=HQAI.APCo and JCCD.VendorGroup=HQAI.APVendorGroup and JCCD.Vendor=HQAI.APVendor and JCCD.APRef=HQAI.APReference and
               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
             and JCCD.CostType=HQAI.JCCostType
  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
  join APTH with (Nolock) on JCCD.APCo=APTH.APCo and JCCD.Mth=APTH.Mth and JCCD.APTrans=APTH.APTrans
join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job




 
  union all
  
  select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCCD.JCTransType,Source,
	Description=null, GLCo=null,ActualHours=null,ActualUnits=null,ActualCost=null,PRCo=null,Employee=null,
  Craft=null,Class=null,EarnFactor=null,VendorGroup=null,Vendor=null,APCo=null,APRef=null,PO=null, MatlGroup=null,Material=null,INCo=null,JCCD.JBBillStatus,
  EMCo=null,EMEquip=null,Amt=null,UnitPrice=null,BillStatus=null,JBRateOption=null,JBLaborRate=null,
  JCJM.Contract, JBTemplate=null,LaborEffecitveDate=null,LaborCategory=null,EquipRateOption=null,JBEquipRate=null,MatlRateOption=null,JBMatlRate=null,
ContDesc=null,DetlDesc=null,JCCD.UniqueAttchID,
  HQAI.AttachmentID,HQAT.Description,HQAT.DocName, ThreshAmt=JCCD.ActualCost
  from JCCD
  Join HQAI with (nolock) on JCCD.MSTicket=HQAI.MSTicket and
               JCCD.JCCo=HQAI.JCCo and JCCD.Job=HQAI.JCJob and JCCD.PhaseGroup=HQAI.JCPhaseGroup and JCCD.Phase=HQAI.JCPhase
             and JCCD.CostType=HQAI.JCCostType
  Join HQAT with (Nolock) on HQAI.AttachmentID=HQAT.AttachmentID
join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job

  union all

   
  select distinct 'PR',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCCD.JCTransType,Source,
	Description=null, GLCo=null,ActualHours=null,ActualUnits=null,ActualCost=null,PRCo=null,Employee=null,
  Craft=null,Class=null,EarnFactor=null,VendorGroup=null,Vendor=null,APCo=null,APRef=null,PO=null, MatlGroup=null,Material=null,INCo=null,JCCD.JBBillStatus,
  EMCo=null,EMEquip=null,Amt=null,UnitPrice=null,BillStatus=null,JBRateOption=null,JBLaborRate=null,
  JCJM.Contract, JBTemplate=null,LaborEffecitveDate=null,LaborCategory=null,EquipRateOption=null,JBEquipRate=null,MatlRateOption=null,JBMatlRate=null,
ContDesc=null,DetlDesc=null,JCCD.UniqueAttchID,
  HQAT.AttachmentID,HQAT.Description, HQAT.DocName, ThreshAmt=JCCD.ActualCost
  from JCCD 
    Inner Join (select PRTH.PRCo, Employee, Job, Phase, Date=Case when PRCO.JCIPostingDate = 'N' then PREndDate else PostDate end,
							PRTH.UniqueAttchID  
							from PRTH
									Inner Join PRCO on PRTH.PRCo=PRCO.PRCo
  where PRTH.UniqueAttchID is not null) as c
     on JCCD.PRCo=c.PRCo and JCCD.Job=c.Job and JCCD.Employee=c.Employee and  c.Phase=JCCD.Phase and c.Date=JCCD.ActualDate
join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job
  Join HQAT with (nolock) on c.UniqueAttchID=HQAT.UniqueAttchID

 union all
 
  select distinct 'JC',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCCD.JCTransType,Source,
	Description=null, GLCo=null,ActualHours=null,ActualUnits=null,ActualCost=null,PRCo=null,Employee=null,
  Craft=null,Class=null,EarnFactor=null,VendorGroup=null,Vendor=null,APCo=null,APRef=null,PO=null, MatlGroup=null,Material=null,INCo=null,JCCD.JBBillStatus,
  EMCo=null,EMEquip=null,Amt=null,UnitPrice=null,BillStatus=null,JBRateOption=null,JBLaborRate=null,
  JCJM.Contract, JBTemplate=null,LaborEffecitveDate=null,LaborCategory=null,EquipRateOption=null,JBEquipRate=null,MatlRateOption=null,JBMatlRate=null,
ContDesc=null,DetlDesc=null,JCCD.UniqueAttchID,
  HQAT.AttachmentID,HQAT.Description,HQAT.DocName, ThreshAmt=JCCD.ActualCost
  from JCCD
  Join HQAT with (Nolock) on HQAT.UniqueAttchID=JCCD.UniqueAttchID
join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job
  --new JC source, link on HQAT.unique...

  union all
 
    select distinct 'IN',JCCD.JCCo, JCCD.Mth, JCCD.CostTrans, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType,
  PostedDate,ActualDate,JCCD.JCTransType,Source,
	Description=null, GLCo=null,ActualHours=null,ActualUnits=null,ActualCost=null,PRCo=null,Employee=null,
  Craft=null,Class=null,EarnFactor=null,VendorGroup=null,Vendor=null,APCo=null,APRef=null,PO=null, MatlGroup=null,Material=null,INCo=null,JCCD.JBBillStatus,
  EMCo=null,EMEquip=null,Amt=null,UnitPrice=null,BillStatus=null,JBRateOption=null,JBLaborRate=null,
  JCJM.Contract, JBTemplate=null,LaborEffecitveDate=null,LaborCategory=null,EquipRateOption=null,JBEquipRate=null,MatlRateOption=null,JBMatlRate=null,
ContDesc=null,DetlDesc=null,INMO.UniqueAttchID,
  HQAT.AttachmentID,HQAT.Description,HQAT.DocName, ThreshAmt=JCCD.ActualCost
  from JCCD

  Join HQAI with (Nolock) on JCCD.INCo=HQAI.INCo and JCCD.Loc=HQAI.INLoc and JCCD.MO=HQAI.MO and JCCD.MOItem=HQAI.MOItem 
      and JCCD.GLCo=HQAI.GLCo and JCCD.GLTransAcct=HQAI.GLAcct
  join INMO with (Nolock) on HQAI.INCo=INMO.INCo and HQAI.MO=INMO.MO 
  Join HQAT with (Nolock) on HQAT.AttachmentID=HQAI.AttachmentID
join JCJM with(nolock) on JCCD.JCCo=JCJM.JCCo and JCCD.Job=JCJM.Job






GO
GRANT SELECT ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [public]
GRANT INSERT ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [public]
GRANT DELETE ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [public]
GRANT SELECT ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCRatesUnbilledAnalysis] TO [Viewpoint]
GO
