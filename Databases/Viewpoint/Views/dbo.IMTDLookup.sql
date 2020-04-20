SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMTDLookup] as select bIMTD.*, DDUD.ColumnName
   From bIMTD join IMTR on IMTR.RecordType=bIMTD.RecordType
                   inner join DDUD on DDUD.Form=IMTR.Form and bIMTD.Seq=DDUD.Seq
                   and bIMTD.Identifier=DDUD.Identifier

GO
GRANT SELECT ON  [dbo].[IMTDLookup] TO [public]
GRANT INSERT ON  [dbo].[IMTDLookup] TO [public]
GRANT DELETE ON  [dbo].[IMTDLookup] TO [public]
GRANT UPDATE ON  [dbo].[IMTDLookup] TO [public]
GO
