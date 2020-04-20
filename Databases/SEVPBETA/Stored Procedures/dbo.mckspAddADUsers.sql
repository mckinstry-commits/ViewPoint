SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[mckspAddADUsers]
(
	@Group varchar(30)
,	@DefCompany tinyint	
)
as

--select * from sysusers

if not exists ( select 1 from sysusers where name = 'MCKINSTRY\' + @Group )
begin
	print '- Group ''' + @Group + ''' does not have rights to this database.'
	return -1
end
else
begin
	print '+ Group ''' + @Group + ''' does have rights to this database.'
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
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
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
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
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
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
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
		)
		SELECT 
			'MCKINSTRY\' + sAMAccountName as NetworkLogin  
		,	ISNULL(givenName, '') + + ISNULL(sn, '') as FullName
		,	mail EmailAddress
		,	@DefCompany
		FROM 
			OpenQuery(ADSI, '<LDAP://mckdc01.mckinstry.com>;(&(objectClass=*)(memberOf=CN=ViewpointUsers,OU=Viewpoint,OU=Security Groups,OU=Mckinstry Co.,DC=mckinstry,DC=com)); givenName, sn, mail, objectCategory, cn, userAccountControl, sAMAccountName;subtree')
		WHERE
			userAccountControl & 2 = 0
		and	'MCKINSTRY\' + sAMAccountName not in
		(
			select distinct [VPUserName] from vDDUP 
		)
	end

end
GO
