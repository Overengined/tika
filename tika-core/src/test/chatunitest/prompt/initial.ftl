<#--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements. See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
Generate a test for focal method `${method_sig}` in `${class_name}`.

The complete focal-method context is:
```${full_fm}```

<#if method_sig?starts_with("normalizeMediaType(")>
Call the static focal method directly. Assert `"image/png"` for `"image/ocr-png"`, assert `"image/jpeg"` is unchanged, and assert null for null. Do not instantiate the focal class and do not mock this test.
<#elseif method_sig?starts_with("getExtension(")>
Use the declared-type branch: create `Metadata`, set `Metadata.CONTENT_TYPE` to `"application/pdf"`, create the focal object with `new EmbeddedDocumentUtil(new ParseContext())`, acquire the stream with `TikaInputStream.get(new byte[0])` in try-with-resources, and assert that the focal method returns `".pdf"`. Do not call `Detector.detect` directly and do not mock this test.
<#elseif method_sig?starts_with("getExtensionForMediaType(")>
Call the static focal method directly. Assert `".pdf"` for `"application/pdf"`, `".png"` for `"image/ocr-png"`, and `""` for null. Do not call `MimeType`, `MimeTypes`, or the private `getRegisteredMimeType` helper from the test.
<#elseif method_sig?starts_with("generateResourceName(")>
The enum is nested. Use exactly `EmbeddedDocumentUtil.EmbeddedResourcePrefix.EMBEDDED`; the constants are only `EMBEDDED`, `IMAGE`, and `THUMBNAIL`. Assert `"embedded-1.pdf"` for count 1 and media type `"application/pdf"`.
<#elseif method_sig?starts_with("recordEmbeddedStreamException(")>
Use a Mockito `Metadata` mock and an `IOException`. After calling the static focal method, verify `metadata.add(TikaCoreProperties.TIKA_META_EXCEPTION_EMBEDDED_STREAM, ExceptionUtils.getFilteredStackTrace(exception))`. Do not compare the stack trace to a hand-written literal.
<#elseif method_sig?starts_with("shouldParseEmbedded(")>
This is an instance delegator. Mock `EmbeddedDocumentExtractor`, put it in a real `ParseContext` with `context.set(EmbeddedDocumentExtractor.class, extractor)`, construct `EmbeddedDocumentUtil` with that context, stub `extractor.shouldParseEmbedded(metadata)`, call the focal instance method, assert the stubbed result, and verify the invocation. Do not invent metadata properties and do not invoke the focal method statically.
<#elseif method_sig?starts_with("parseEmbedded(")>
This is an instance delegator. Mock `EmbeddedDocumentExtractor`, put it in a real `ParseContext`, and construct `EmbeddedDocumentUtil` with that context. Mock `TikaInputStream` and `ContentHandler`, use a real `Metadata`, call the focal method, then verify exactly `extractor.parseEmbedded(input, handler, metadata, context, true)`. Do not instantiate `TikaInputStream`, implement `ContentHandler`, or invoke a parser directly.
</#if>

<#if method_invocation_codes_outerclass?has_content>
Existing invocations elsewhere in the project are:
<#list method_invocation_codes_outerclass as invoke_code>
```${invoke_code}```
</#list>
<#elseif method_invocation_codes_innerclass?has_content>
Existing invocations in the focal class are:
<#list method_invocation_codes_innerclass as invoke_code>
```${invoke_code}```
</#list>
</#if>

<#if other_method_sigs?has_content>
Other focal-class signatures are `${other_method_sigs}`.
</#if>
<#list c_deps?keys as key>
Dependency `${key}` has this relevant context:
```${c_deps[key]}```
</#list>
<#list m_deps?keys as key>
Dependency `${key}` has this relevant method context:
```${m_deps[key]}```
</#list>

Return one complete, minimal, passing Java test compilation unit and nothing else.
