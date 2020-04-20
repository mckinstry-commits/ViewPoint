USE Viewpoint
GO

IF TYPE_ID('[dbo].[McKtyInvoiceList]') IS NOT NULL
	DROP TYPE dbo.McKtyInvoiceList
	Print 'DROP TYPE dbo.McKtyInvoiceList'
GO

Print 'CREATE TYPE dbo.McKtyInvoiceList'

/* Create a table type */
CREATE TYPE dbo.McKtyInvoiceList AS TABLE
( 
	InvoiceNumber VARCHAR(10)
);

GO  