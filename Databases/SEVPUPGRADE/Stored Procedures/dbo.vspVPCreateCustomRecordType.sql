SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPCreateCustomRecordType]
/*************************************
*	Created by:		FDT 9/8/10 - Created by Francine to be used by script vDDCustomCreate.sql
*                                written for TK-04280
*					JG	9/9/11 - Moved the edit next to the new.
*	Modified by:	
*   
*   Description:
*
*   This script creates all the records necessary to define a toolbar 'button'
*   for a particular record type.
*
*   @RecordName is the record type name, example: 'PMRFI', 'PMMeetingMinutes', etc.
*   It is a foreign key into vDDFH.Form.
*
*   @GroupType tells you what kind of button it is going to be.  Currently,
*   'NEW', 'EDIT' 'CREATE' and 'RELATE' are some preset types, while 'ALL'
*   causes 'NEW' 'EDIT' and 'RELATE' buttons to be created.  'Custom' is
*   the "base" parameter; all other types get translated into a call using
*   'Custom'.
*
*   @Actions will be NULL for most group types, but should contain a comma
*   delimited string of action IDs if the type is 'CREATE'.
*   
*   First, the script checks to see if there is a vDDCustomRecordTypes record
*   with @RecordName.  If there is, it puts the ID int @RecTypeId.  If there
*   isn't, it creates it and puts the id into @RecTypeId
*
*   Next, it creates a vDDCustomGroups record, representing the "group",
*   which translates to a button or menu pulldown on the toolbar.
*
*   Finally, it adds one or more vDDCustomActionGroup records, one for each
*   item in @Actions, or a preset item for a standard group type.  There will
*   be one vDDCustomActionGroup record for each action which can be taken
*   from this button/menu item.
*
*   Here are some examples of what calls might be made:
*
*   add a "CREATE" menu item on the toolbar, which contains four actions
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'CREATE', '15,16,18,20'
*
*   add the standard EDIT button, which is a single button, with tooltip
*   text that says "Edit Record" and a single action (id = 5)
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'EDIT'
*
*   add the standard NEW button, which is a single button, with tooltip
*   text that says "New Record" and a single action (id = 4)
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'NEW'
*
*   adds all standard buttons; EDIT, NEW, RELATE, REPORTS
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'ALL'
*
*   this will add a custom menu item to the toolbar.  Tooltip text will say
*   'Things to do' and it will have two action items to select from.  Order is
*   15, which puts it after all the standard buttons but before the reports item.
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'CUSTOM', '21,22', 'Things to do', 15, 'things_icon'
*
*   this will add a custom button to the toolbar.  Tooltip text will say
*   'Point of Sale' and clicking it will launch action items 18.  Order is
*   101, which puts it after the reports item.  Since it is a single action
*   item, the icon is null (action icon will be used)
*   EXECUTE [dbo].[vspVPCreateCustomRecordType] 'APUnappInv', 'CUSTOM', '18', 'Point of Sale', 101, NULL
*
**************************************/
	(@RecordName varchar(128),
     @GroupType varchar(20), 
     @Actions varchar(100) = NULL,
     @GroupName varchar(30) = NULL,
     @GroupOrder int = 0,
     @GroupImageKey varchar(128) = NULL)
AS
declare @ErrMessage varchar(1000)
declare @rc int
SET @rc = 0

IF not @GroupType = 'CUSTOM'
    begin
    -- if group type is 'ALL', create all the standard types, in the standard
	-- order, with standard icons, etc.
		IF @GroupType = 'ALL'
		begin
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'NEW'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'EDIT'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'RELATE'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'REPORT'
		end
		ELSE IF @GroupType = 'NEW'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', '4', 'Create New Item', 1, NULL
		ELSE IF @GroupType = 'EDIT'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', '5', 'Open Item', 2, NULL
		ELSE IF @GroupType = 'CREATE'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', @Actions, 'Create Related Item', 3, 'create_related'			
		ELSE IF @GroupType = 'RELATE'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', '21', 'Relate Item', 4, 'relate_item'
		ELSE IF @GroupType = 'TASK'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', @Actions, 'Tasks', 100, 'tasks'
		ELSE IF @GroupType = 'REPORT'
			EXECUTE [dbo].[vspVPCreateCustomRecordType] @RecordName, 'CUSTOM', @Actions, 'Reports', 99, 'R_16_REPORT'
		goto EXITS
    end

-- if we have gotten this far, we have a 'custom' button, and all the parameters
-- should have non-default values in them     
DECLARE @RecTypeId int

-- add the vDDCustomRecordTypes (record type) or get the id for an already existing one
SET @RecTypeId = (SELECT Id FROM dbo.vDDCustomRecordTypes WHERE Name = @RecordName)
IF @RecTypeId is NULL
   begin
      INSERT INTO dbo.vDDCustomRecordTypes (Name) VALUES (@RecordName)
      SET @RecTypeId = (SELECT Id FROM dbo.vDDCustomRecordTypes WHERE Name = @RecordName)
      IF @RecTypeId is NULL
         begin
         SET @ErrMessage = 'Could not INSERT ' + @RecordName + ' into vDDCustomRecordTypes'
         GOTO ONERROR
         end
   end

IF @GroupName is null
begin
	SET @ErrMessage = '@GroupName cannot be null when group type is CUSTOM '
	GOTO ONERROR
end

-- locate or insert the group record
DECLARE @GroupId int
SET @GroupId = (SELECT Id FROM dbo.vDDCustomGroups WHERE Name = @GroupName and RecordTypeId = @RecTypeId)
IF @GroupId is NULL
    begin
	INSERT INTO dbo.vDDCustomGroups (Name, [Order], ImageKey, RecordTypeId)
	VALUES (@GroupName, @GroupOrder, @GroupImageKey, @RecTypeId)
	SET @GroupId = (SELECT Id FROM dbo.vDDCustomGroups WHERE Name = @GroupName and RecordTypeId = @RecTypeId)
	end

-- now get the ID of the group record you just inserted
IF @GroupId is NULL
     begin
     SET @ErrMessage = 'Could not INSERT ' + @GroupName + ' into vDDCustomGroups'
     GOTO ONERROR
     end

-- now create a temporary table containing all the action id's in @Actions
IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#tempaction') and type = 'U')
BEGIN
	DROP TABLE #tempaction
END
IF not @Actions is NULL
BEGIN
	create table #tempaction (actionid int)
	insert into #tempaction (actionid) select * from vfCoTableFromArray(@Actions)

	-- INSERT one record for each action
	INSERT dbo.vDDCustomActionGroup (ActionId, GroupId)
	select actionid, @GroupId from #tempaction

	drop table #tempaction
END

/* if no errors have been raised, bypass ONERROR */
goto EXITS

ONERROR:
select @rc = 1

EXITS:
	SET NOCOUNT OFF
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#add_group') and type = 'P')
	BEGIN
	   DROP PROCEDURE #add_group
	END
	if @rc = 0 raiserror('RPRT20110311.sql successful!',9,-1)
	else raiserror(@ErrMessage, 11, -1)


GO
GRANT EXECUTE ON  [dbo].[vspVPCreateCustomRecordType] TO [public]
GO
