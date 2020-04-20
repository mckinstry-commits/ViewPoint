SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDFormCountries] AS
	SELECT * FROM vDDFormCountries;


GO
GRANT SELECT ON  [dbo].[DDFormCountries] TO [public]
GRANT INSERT ON  [dbo].[DDFormCountries] TO [public]
GRANT DELETE ON  [dbo].[DDFormCountries] TO [public]
GRANT UPDATE ON  [dbo].[DDFormCountries] TO [public]
GO
