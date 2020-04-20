SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.SMContact
AS
SELECT     HQContactID, ContactGroup, ContactSeq, FirstName, MiddleInitial, LastName, FirstName + ' ' + LastName AS 'FullName', CourtesyTitle, Title, 
                      Organization, Phone, PhoneExtension, Cell, Fax, Email, Address, AddressAdditional, City, State, Country, Zip, Notes, UniqueAttchID, KeyID
FROM         dbo.HQContact

GO
GRANT SELECT ON  [dbo].[SMContact] TO [public]
GRANT INSERT ON  [dbo].[SMContact] TO [public]
GRANT DELETE ON  [dbo].[SMContact] TO [public]
GRANT UPDATE ON  [dbo].[SMContact] TO [public]
GO
