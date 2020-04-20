SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udMeterHis] as select a.* From budMeterHis a
GO
GRANT SELECT ON  [dbo].[udMeterHis] TO [public]
GRANT INSERT ON  [dbo].[udMeterHis] TO [public]
GRANT DELETE ON  [dbo].[udMeterHis] TO [public]
GRANT UPDATE ON  [dbo].[udMeterHis] TO [public]
GRANT SELECT ON  [dbo].[udMeterHis] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udMeterHis] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udMeterHis] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udMeterHis] TO [Viewpoint]
GO
