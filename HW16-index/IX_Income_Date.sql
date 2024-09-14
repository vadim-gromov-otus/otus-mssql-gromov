USE [HomeBookkeeping]
GO

CREATE NONCLUSTERED INDEX [IX_Income_Date] ON [dbo].[Income]
(
	[Date] ASC
)
INCLUDE([SubjectID])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


