SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[PMRFIResponseDoc]

/***********
 Created:  DH 4/13/2011
 Modified: GF 08/24/2011 TK-07945
 
 Usage:  Used to return Merge Table fields for the PM RFI Document.  Selects all columns 
		 from PMRFIResponse and formats the Notes column so that it can be used to show 
		 each response separated by a line in the RFI Document template.  When using the view
		 for the RFI document templates, the columns from this view should be added to the Table
		 Merge fields in the PM Create and Send Templates form.

************/		 

as

SELECT    a.*

		, '     ' + ISNULL(a.Notes, '') --Field indented five spaces
            --+ CHAR(13) + CHAR(10)
            --+ '..............................................................................................................................................................................'
             as FormattedNotes
FROM PMRFIResponse a





GO
GRANT SELECT ON  [dbo].[PMRFIResponseDoc] TO [public]
GRANT INSERT ON  [dbo].[PMRFIResponseDoc] TO [public]
GRANT DELETE ON  [dbo].[PMRFIResponseDoc] TO [public]
GRANT UPDATE ON  [dbo].[PMRFIResponseDoc] TO [public]
GRANT SELECT ON  [dbo].[PMRFIResponseDoc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMRFIResponseDoc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMRFIResponseDoc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMRFIResponseDoc] TO [Viewpoint]
GO
