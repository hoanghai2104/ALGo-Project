tableextension 50109 ServiceItemLine extends "Service Item Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; orderLineNo; Integer) { }

        field(50102; FunctionalLocationID; GUID)
        {

            Description = 'Poste technique de l’ordre de travail';
            Caption = 'Poste technique';
            FieldClass = Normal;
            ObsoleteState = Removed;
            ObsoleteReason = 'Remove';
            trigger OnValidate()
            var
                ServiceHeaderRef: RecordRef;
                ShipToCode: Code[20];
            begin
                // ServiceHeaderRef := Rec;
                // shiptoAddressCodeunit.RetriveFunctionalLocationCode(ServiceHeaderRef, ShipToCode);
                // Rec.Validate("Ship-to Code", ShipToCode);
            end;

        }



        field(50101; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnAfterInsert()
    begin
        SyncShiptoSILToServiceHeader();
    end;

    procedure SyncShiptoSILToServiceHeader()
    var
        serviceHeader: Record "Service Header";
        serviceItemline: Record "Service Item Line";
        ShipToAddress: Record "Ship-to Address";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Order then
            exit;
        serviceItemline.Reset();
        serviceItemline.SetAscending("Line No.", false);
        serviceItemline.SetRange("Document Type", Rec."Document Type"::Order);
        serviceItemline.SetRange("Document No.", Rec."Document No.");

        if serviceItemline.FindFirst() then begin
            if serviceHeader.Get(serviceItemline."Document Type", serviceItemline."Document No.") then begin
                serviceHeader."Ship-to Code" := serviceItemline."Ship-to Code";
                if ShipToAddress.Get(serviceItemline."Customer No.", serviceItemline."Ship-to Code") then begin
                    serviceHeader."Ship-to Name" := ShipToAddress."Name";
                    serviceHeader."Name 2" := ShipToAddress."Name 2";
                    serviceHeader."Ship-to Address" := ShipToAddress."Address";
                    serviceHeader."Ship-to Address 2" := ShipToAddress."Address 2";
                    serviceHeader."Ship-to City" := ShipToAddress."City";
                    serviceHeader."Ship-to County" := ShipToAddress."County";
                    serviceHeader."Ship-to Post Code" := ShipToAddress."Post Code";
                    serviceHeader."Ship-to Country/Region Code" := ShipToAddress."Country/Region Code";
                    serviceHeader."Ship-to Contact" := ShipToAddress."Contact";
                    serviceHeader."Ship-to Phone" := ShipToAddress."Phone No.";
                    serviceHeader."Ship-to E-mail" := ShipToAddress."E-mail";
                end;

                serviceHeader.Modify();
            end;
        end;

    end;

}