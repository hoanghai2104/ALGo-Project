permissionset 50101 IntegrationTable
{
    Assignable = true;
    Permissions =
         tabledata "CDS msdyn_FunctionalLocation" = RIMD,
         tabledata "ELCA CRM Sync. Buffer" = RIMD,
         table "Ship-to Address" = X,
         table "CDS msdyn_FunctionalLocation" = X,
         table "ELCA CRM Sync. Buffer" = X;
}