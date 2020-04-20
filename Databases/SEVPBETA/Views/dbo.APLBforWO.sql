SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 04/12/06
	Modified by:
	Purpose:	 to display EQ# - Desc, EQ Component type and component for WO lines */
  
   
   CREATE       view [dbo].[APLBforWO] as select APLB.Co,APLB.Mth,APLB.BatchId, APLB.BatchSeq,APLB.APLine,EMEM.EMCo,EMEM.Equipment,
			'EQDesc' = 'EQ#: ' + convert(varchar(10),isnull(APLB.Equip,'')) + ' - ' +  isnull(EMEM.Description,''),
			'EQComp' = convert(varchar(10),isnull(APLB.CompType,'')) + ' - ' + 
				convert(varchar(10),isnull(APLB.Component,'')) + 
				case APLB.Component when null then '' else ' - ' + (select Description from EMEM e2 
					where APLB.EMCo=e2.EMCo and APLB.Component=e2.Equipment) end
 		from APLB join EMEM on APLB.EMCo=EMEM.EMCo and APLB.Equip=EMEM.Equipment where APLB.LineType = 5 or (APLB.LineType = 6 and ItemType=5)

GO
GRANT SELECT ON  [dbo].[APLBforWO] TO [public]
GRANT INSERT ON  [dbo].[APLBforWO] TO [public]
GRANT DELETE ON  [dbo].[APLBforWO] TO [public]
GRANT UPDATE ON  [dbo].[APLBforWO] TO [public]
GO
