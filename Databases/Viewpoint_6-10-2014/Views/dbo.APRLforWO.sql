SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 11/29/05
	Modified by:
	Purpose:	 to display EQ# - Desc, EQ Component type and component for WO lines */
  
   
   CREATE       view [dbo].[APRLforWO] as select APRL.APCo,APRL.VendorGroup, APRL.Vendor, APRL.InvId, APRL.Line, EMEM.EMCo,EMEM.Equipment,
			'EQDesc' = 'EQ#: ' + convert(varchar(10),isnull(APRL.Equip,'')) + ' - ' +  isnull(EMEM.Description,''),
			'EQComp' = convert(varchar(10),isnull(APRL.CompType,'')) + ' - ' + 
				convert(varchar(10),isnull(APRL.Component,'')) + 
				case APRL.Component when null then '' else ' - ' + (select Description from EMEM e2 
					where APRL.EMCo=e2.EMCo and APRL.Component=e2.Equipment) end
 		from APRL join EMEM on APRL.EMCo=EMEM.EMCo and APRL.Equip=EMEM.Equipment where APRL.LineType = 5 or (APRL.LineType = 6 and ItemType=5)

GO
GRANT SELECT ON  [dbo].[APRLforWO] TO [public]
GRANT INSERT ON  [dbo].[APRLforWO] TO [public]
GRANT DELETE ON  [dbo].[APRLforWO] TO [public]
GRANT UPDATE ON  [dbo].[APRLforWO] TO [public]
GRANT SELECT ON  [dbo].[APRLforWO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APRLforWO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APRLforWO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APRLforWO] TO [Viewpoint]
GO
