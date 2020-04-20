SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/17/10
-- Description:	SM Contact Seq validation
-- =============================================
CREATE PROCEDURE [dbo].[vspSMContactVal]
(
	@ContactGroup bGroup,
	@Contact varchar(60),
	@ContactSeq int = NULL OUTPUT,
	@Phone bPhone = NULL OUTPUT,
	@PhoneExt varchar(5) = NULL OUTPUT,
	@Cell bPhone = NULL OUTPUT,
	@Fax bPhone = NULL OUTPUT,
	@Email varchar(60) = NULL OUTPUT,
	@Title varchar(30) = NULL OUTPUT,
	@FirstLastName varchar(61) = NULL OUTPUT,
	@msg varchar(255)= NULL OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	IF (@ContactGroup IS NULL)
	BEGIN
		SET @msg = 'Invalid Contact Group.'
		RETURN 1
	END
	
	-- Try to find the contact by the contact sequence
	IF dbo.bfIsInteger(@Contact) = 1 AND LEN(@Contact) <= 9
	BEGIN
		SELECT @ContactSeq = ContactSeq
		FROM dbo.SMContact
		WHERE ContactGroup = @ContactGroup AND ContactSeq = CAST(@Contact AS INT)
	END
	
	--If we didn't find the contact by the contact sequence then try to find them
	--by their name
	IF @ContactSeq IS NULL
	BEGIN
		SELECT @ContactSeq = ContactSeq
		FROM dbo.SMContact
		WHERE ContactGroup = @ContactGroup AND UPPER(FirstName + ' ' + LastName) = UPPER(@Contact)
	END
	
	--If we found too many contacts that match the name then we should
	--not return the contact as a valid contact.
	IF @@rowcount > 1
	BEGIN
		SET @ContactSeq = NULL
	END
	ELSE IF @ContactSeq IS NULL
	BEGIN
		--If we didn't find the contact by their name try to find the closest matching contact name
		SELECT @ContactSeq = ContactSeq
		FROM dbo.SMContact
		WHERE ContactGroup = @ContactGroup AND UPPER(FirstName + ' ' + LastName) LIKE UPPER(@Contact) + '%'
		
		--If we found too many contacts that match the name then we should
		--not return the contact as a valid contact.
		IF @@rowcount > 1
		BEGIN
			SET @ContactSeq = NULL
		END
	END

	--Get the info about the contact if we found a valid contact
	IF @ContactSeq IS NOT NULL
	BEGIN
		SELECT @FirstLastName = FirstName + ' ' + LastName,
			@Phone = Phone,
			@PhoneExt = PhoneExtension,
			@Cell = Cell,
			@Fax = Fax,
			@Email = Email,
			@Title = Title,
			@msg = @FirstLastName
		FROM dbo.SMContact
		WHERE ContactGroup = @ContactGroup AND ContactSeq = @ContactSeq
	END
	ELSE
	BEGIN
		SET @msg = 'Contact not on file.'
		RETURN 1
	END

	RETURN 0
END

/* Testing Framework

Declare
	@ContactGroup bGroup,
	@ContactSeq int,
	@Phone bPhone,
	@PhoneExt varchar(5),
	@Cell bPhone,
	@Fax bPhone,
	@Email varchar(60),
	@Title varchar(30),
	@Notes varchar(max),
	@FirstLastName varchar(61),
	@msg varchar(255)
	
select @ContactGroup=2, @ContactSeq = 3

exec vspSMContactVal
	@ContactGroup, @ContactSeq,
	@Phone OUTPUT,
	@PhoneExt OUTPUT,
	@Cell OUTPUT,
	@Fax OUTPUT,
	@Email OUTPUT,
	@Title OUTPUT,
	@Notes OUTPUT,
	@FirstLastName OUTPUT,
	@msg OUTPUT

select 	@Phone [Phone],	@PhoneExt [Phone Ext],
	@Cell [Cell],
	@Fax [Fax],
	@Email [Email],
	@Title [Title],
	@Notes [Notes],
	@FirstLastName [First Last],
	@msg [Msg]

*/
GO
GRANT EXECUTE ON  [dbo].[vspSMContactVal] TO [public]
GO
