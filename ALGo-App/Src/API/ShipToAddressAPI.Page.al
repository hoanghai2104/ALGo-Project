page 50112 ShipToAddressAPI
{
    PageType = API;
    Caption = 'Ship-to Address API';
#pragma warning disable AA0101
    APIPublisher = 'ELCA';
#pragma warning restore AA0101
    APIGroup = 'elca';
    APIVersion = 'v2.0';
    EntityName = 'shiptoaddress';
    EntitySetName = 'shiptoaddresses';
    SourceTable = "Ship-to Address";
    DelayedInsert = true;
    // SourceTableView = where("Document Type" = const(Order), "Coupled to FS" = const(True));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId) { }
                field(shipToCode; Rec.Code) { }
                field(name; Rec.Name) { }
                field(address; Rec.Address) { }
                field("customerNo"; Rec."Customer No.") { }
                field(msdyn_FunctionalLocationId; Rec.msdyn_FunctionalLocationId) { }

            }
        }
    }
}