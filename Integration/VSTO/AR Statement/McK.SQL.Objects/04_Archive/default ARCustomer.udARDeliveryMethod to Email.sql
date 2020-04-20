/* check count */
SELECT COUNT(Customer)
FROM dbo.ARCM
WHERE Status = 'A' and  udARDeliveryMethod IS NULL
  
UPDATE dbo.ARCM
SET udARDeliveryMethod = 1 -- 1=Email, 2=Mail
WHERE Status = 'A' and  udARDeliveryMethod IS NULL
