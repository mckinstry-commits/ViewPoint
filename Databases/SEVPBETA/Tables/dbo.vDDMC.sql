CREATE TABLE [dbo].[vDDMC]
(
[MenuCategoryID] [int] NOT NULL,
[MenuType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[IconKey] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[vtDDMCMenuCategoryu] on [dbo].[vDDMC] for UPDATE
/*-----------------------------------------------------------------  
 * Created By:	FT 3/9/11
 * Modified By:	GF 10/25/2011 TK-09303 removed raiseerror message
 *
 *  
 *  Update trigger on vDDMC  
 *  
 *  This trigger renames IconKey in DDFH and RPRT entries that use
 *  the updated category
 *  
 */----------------------------------------------------------------  
    
as  
      
if @@rowcount = 0 return  
set nocount on  
      

-- if the Icon column was changed
IF ( UPDATE (IconKey))
BEGIN
	--UPDATE all DDFH records which use this category with the new icon name
	Update vDDFH
	Set vDDFH.IconKey = inserted.IconKey
	from inserted
	--from inserted inner join vDDFH
	WHERE vDDFH.MenuCategoryID = inserted.MenuCategoryID
	
	--UPDATE all RPRT records which use this category with the new icon name
	Update vRPRT
	Set vRPRT.IconKey = inserted.IconKey
	from inserted
	--from inserted inner join vDDFH
	WHERE vRPRT.MenuCategoryID = inserted.MenuCategoryID
END

RETURN





GO
ALTER TABLE [dbo].[vDDMC] ADD CONSTRAINT [PK_vDDMC] PRIMARY KEY CLUSTERED  ([MenuCategoryID]) ON [PRIMARY]
GO
