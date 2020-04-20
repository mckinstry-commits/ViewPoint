SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.PRCraftClassTemplateAllowance 
AS
SELECT * FROM dbo.vPRCraftClassTemplateAllowance 
GO
GRANT SELECT ON  [dbo].[PRCraftClassTemplateAllowance] TO [public]
GRANT INSERT ON  [dbo].[PRCraftClassTemplateAllowance] TO [public]
GRANT DELETE ON  [dbo].[PRCraftClassTemplateAllowance] TO [public]
GRANT UPDATE ON  [dbo].[PRCraftClassTemplateAllowance] TO [public]
GO
