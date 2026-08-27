page 50111 ServiceItemAPI
{
    PageType = API;
    Caption = 'Service Item API';
#pragma warning disable AA0101
    APIPublisher = 'ELCA';
#pragma warning restore AA0101
    APIGroup = 'elca';
    APIVersion = 'v2.0';
    EntityName = 'serviceitem';
    EntitySetName = 'serviceitems';
    SourceTable = "Service Item";
    DelayedInsert = true;
    SourceTableView = where("Coupled to FS" = const(True));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    layout
    {
        area(Content)
        {
            repeater(serviceorder)
            {
                field(systemId; Rec.SystemId) { }
                field("serviceItemNo"; Rec."No.")
                {
                }
                field("shipToCode"; Rec."Ship-to Code") { }
                field(msdynCustomerAssetId; Rec.msdyn_customerassetId) { }
                field("installationDate"; Rec."Installation Date") { }
                field("dateInstallationActif"; Rec."Date installation actif") { }
                field("customerNo"; Rec."Customer No.") { }
                field(description; Rec.Description) { }
            }
        }
    }
}