codeunit 71891734 "DGOG Gantt Save Handler"
{
    procedure ApplyPendingChanges(PendingChangesJson: Text)
    var
        Changes: JsonArray;
        ChangeToken: JsonToken;
    begin
        if PendingChangesJson = '' then
            exit;
        if not Changes.ReadFrom(PendingChangesJson) then
            Error('The pending change payload is not valid JSON.');

        foreach ChangeToken in Changes do
            ApplySingleChange(ChangeToken.AsObject());

        Commit();
    end;

    var
        ValidationHelper: Codeunit "DGOG Gantt Validation Helper";

    local procedure ApplySingleChange(ChangeObject: JsonObject)
    var
        SourceTableId: Integer;
        FieldId: Integer;
        SourceRecordIdText: Text;
        NewValueText: Text;
        SourceRecordId: RecordId;
        SourceRef: RecordRef;
    begin
        SourceTableId := GetInteger(ChangeObject, 'sourceTableId');
        FieldId := GetInteger(ChangeObject, 'fieldId');
        SourceRecordIdText := GetText(ChangeObject, 'sourceRecordId');
        NewValueText := GetText(ChangeObject, 'newValue');

        if (SourceTableId = 0) or (FieldId = 0) or (SourceRecordIdText = '') then
            exit;

        ValidationHelper.EnsureTableExists(SourceTableId);
        ValidationHelper.EnsureFieldExists(SourceTableId, FieldId);

        Evaluate(SourceRecordId, SourceRecordIdText);
        SourceRef.Open(SourceTableId);
        if not SourceRef.Get(SourceRecordId) then
            Error('Source record %1 was not found in table %2.', SourceRecordIdText, SourceTableId);

        ValidationHelper.SetFieldFromText(SourceRef, FieldId, NewValueText);
        SourceRef.Modify(true);
    end;

    local procedure GetInteger(SourceObject: JsonObject; KeyName: Text): Integer
    var
        JsonToken: JsonToken;
    begin
        if not SourceObject.Get(KeyName, JsonToken) then
            exit(0);
        exit(JsonToken.AsValue().AsInteger());
    end;

    local procedure GetText(SourceObject: JsonObject; KeyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if not SourceObject.Get(KeyName, JsonToken) then
            exit('');
        exit(JsonToken.AsValue().AsText());
    end;
}