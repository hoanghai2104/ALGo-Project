codeunit 50106 ShipToAddress
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", OnAfterLookupPostCode, '', false, false)]
    local procedure "Ship-to Address_OnAfterLookupPostCode"(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address")
    begin
        ShipToAddress.Dataverse_PostCode := ShipToAddress."Post Code";
        ShipToAddress.Dataverse_City := ShipToAddress.City;
        ShipToAddress."Dataverse_Country/Region Code" := ShipToAddress."Country/Region Code";

    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", OnAfterLookupCity, '', false, false)]
    local procedure "Ship-to Address_OnAfterLookupCity"(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address")
    begin
        ShipToAddress.Dataverse_PostCode := ShipToAddress."Post Code";
        ShipToAddress.Dataverse_City := ShipToAddress.City;
        ShipToAddress."Dataverse_Country/Region Code" := ShipToAddress."Country/Region Code";

    end;

    [EventSubscriber(ObjectType::Page, Page::"Ship-to Address", OnAfterOnNewRecord, '', false, false)]
    local procedure "Ship-to Address_OnAfterOnNewRecord"(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        ShipToAddress.Dataverse_PostCode := ShipToAddress."Post Code";
        ShipToAddress.Dataverse_City := ShipToAddress.City;
        ShipToAddress."Dataverse_Country/Region Code" := ShipToAddress."Country/Region Code";

    end;


    procedure RetriveFunctionalLocationCode(var recRef: RecordRef; var ShipToCode: Code[20]): Boolean
    var
        ShipToAddressRec: Record "Ship-to Address";
        FunctionalLocationID: Guid;
    begin

        ShipToAddressRec.Reset();
        FunctionalLocationID := recRef.Field('FunctionalLocationID').Value;
        ShipToAddressRec.SetRange("msdyn_FunctionalLocationId", FunctionalLocationID);
        if not ShipToAddressRec.FindFirst() then
            exit(false);

        ShipToCode := ShipToAddressRec.Code;

        exit(true);
    end;

    procedure RetriveFunctionalLocationGUID(var recRef: RecordRef; var FunctionalLocationID: Guid): Boolean
    var
        ShipToAddressRec: Record "Ship-to Address";
        customerNo: Code[20];
        shiptoCode: Code[20];
    begin

        ShipToAddressRec.Reset();
        shiptoCode := recRef.Field('Ship-to Code').Value;
        ShipToAddressRec.SetRange("Code", shiptoCode);
        customerNo := recRef.Field('Customer No.').Value;
        ShipToAddressRec.SetRange("Customer No.", customerNo);
        if not ShipToAddressRec.FindFirst() then
            exit(false);

        FunctionalLocationID := ShipToAddressRec.msdyn_FunctionalLocationId;

        exit(true);
    end;
    //in
}