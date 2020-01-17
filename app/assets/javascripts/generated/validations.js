// This file was automatically generated via `rails validations:generate`.
validations = {"user":{"security_question_responses":{"associated":{}},"password":{"presence":{"if":"password_required?"},"confirmation":{"case_sensitive":true,"if":"password_required?"},"length":{"allow_blank":true,"minimum":8,"maximum":128}},"email":{"format":{"with":"(?-mix:\\A[^@\\s]+@([^@\\s]+\\.)+[^@\\s]+\\z)","allow_blank":true,"message":"is invalid"},"uniqueness":{"case_sensitive":false}},"oim_id":{"presence":{},"uniqueness":{"case_sensitive":false}},"person":{"associated":{}}},"benefit_sponsors/benefit_packages/benefit_package":{"sponsored_benefits":{"associated":{}},"title":{"presence":{}},"probation_period_kind":{"presence":{}},"is_default":{"presence":{}},"is_active":{"presence":{}}},"benefit_sponsors/organizations/aca_shop_dc_employer_profile":{"office_locations":{"associated":{},"presence":{}},"contact_method":{"presence":{},"inclusion":{"allow_blank":false,"in":["paper_and_electronic","paper_only","electronic_only"],"message":"%{value} is not a valid contact method"}},"inbox":{"associated":{}},"documents":{"associated":{}}},"benefit_sponsors/organizations/profile":{"office_locations":{"associated":{},"presence":{}},"contact_method":{"presence":{},"inclusion":{"allow_blank":false,"in":["paper_and_electronic","paper_only","electronic_only"],"message":"%{value} is not a valid contact method"}},"inbox":{"associated":{}},"documents":{"associated":{}}},"benefit_sponsors/locations/address":{"zip":{"presence":{},"format":{"allow_blank":false,"with":"(?-mix:\\A\\d{5}(-\\d{4})?\\z)","message":"should be in the form: 12345 or 12345-1234"}},"kind":{"presence":{},"inclusion":{"allow_blank":true,"in":["home","work","mailing","primary","mailing","branch"],"message":"%{value} is not a valid address kind"}},"address_1":{"presence":{"message":"Please enter address_1"}},"city":{"presence":{"message":"Please enter city"}}}}