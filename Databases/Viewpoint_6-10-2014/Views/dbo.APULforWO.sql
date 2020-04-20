SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 08/28/06
	Modified by:
	Purpose:	 to display EQ# - Desc, EQ Component type and component for WO lines in APUnappInv */
  
   
   CREATE       view [dbo].[APULforWO] as select APUL.APCo,APUL.UIMth, APUL.UISeq, APUL.Line, EMEM.EMCo,EMEM.Equipment,
			'EQDesc' = 'EQ#: ' + convert(varchar(10),isnull(APUL.Equip,'')) + ' - ' +  isnull(EMEM.Description,''),
			'EQComp' = convert(varchar(10),isnull(APUL.CompType,'')) + ' - ' + 
				convert(varchar(10),isnull(APUL.Component,'')) + 
				case APUL.Component when null then '' else ' - ' + (select Description from EMEM e2 
					where APUL.EMCo=e2.EMCo and APUL.Component=e2.Equipment) end
 		from APUL join EMEM on APUL.EMCo=EMEM.EMCo and APUL.Equip=EMEM.Equipment where APUL.LineType = 5 or (APUL.LineType = 6 and ItemType=5)

GO
GRANT SELECT ON  [dbo].[APULforWO] TO [public]
GRANT INSERT ON  [dbo].[APULforWO] TO [public]
GRANT DELETE ON  [dbo].[APULforWO] TO [public]
GRANT UPDATE ON  [dbo].[APULforWO] TO [public]
GRANT SELECT ON  [dbo].[APULforWO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APULforWO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APULforWO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APULforWO] TO [Viewpoint]
GO
