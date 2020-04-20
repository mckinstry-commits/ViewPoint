USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckspAddADUsers]    Script Date: 9/4/2014 10:52:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[mckspAddADUsers]
(
	@Group varchar(30)
,	@DefCompany tinyint	
,	@ReturnMessage VARCHAR(MAX) OUTPUT
)
as

--select * from sysusers
/*
2014.11.17 - LWO - Altered ADSI path for PM Training users ( group was moved in AD)
*/

if not exists ( select 1 from sysusers where name = 'MCKINSTRY\' + @Group )
begin
	SET @ReturnMessage = '- Group ''' + @Group + ''' does not have rights to this database.'
	print @ReturnMessage
	return -1
end
else
begin
	SET @ReturnMessage = '+ Group ''' + @Group + ''' does have rights to this database.'
	print @ReturnMessage
end

begin
	if @Group='ERPIntegrationTeam'
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' '+ ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ERPIntegrationTeam,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	end
	if @Group='ERPReportingTeam' 
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' ' + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ERPReportingTeam,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)	
	end
	if @Group='ViewPointTestUsers'  
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' ' + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ViewPointTestUsers,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	end
	if @Group='ViewpointUsers'  
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' ' + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ViewpointUsers,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	END
    if @Group='Viewpoint PM Training Users'  
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)	--DECLARE @DefCompany bCompany = 1
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' ' + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=Viewpoint PM Training Users,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	end
	if @Group='ViewpointPayrollUsers'  
	begin
		insert vDDUP 
		(
			VPUserName
		,	FullName
		,	EMail
		,	DefaultCompany
		,	SendViaSmtp
		,	EnterAsTab
		,	ToolTipHelp
		,	ExtendControls
		,	SmartCursor
		,	SavePrinterSettings
		,	AltGridRowColors
		,	SaveLastUsedParameters
		)	--DECLARE @DefCompany bCompany = 1
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + ' ' + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		,	'Y'	--SendViaSmtp
		,	'Y'	--EnterAsTab
		,	'Y' --ToolTipHelp
		,	'Y'	--ExtendControls
		,	'Y'	--SmartCursor
		,	'Y'	--SavePrinterSettings
		,	'Y'	--AltGridRowColors
		,	'Y'	--SaveLastUsedParameters
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ViewpointPayrollUsers,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	end
end
go


grant exec on [mckspAddADUsers] to public
go
