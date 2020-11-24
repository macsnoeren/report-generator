#https://blog.formpl.us/how-to-generate-word-documents-from-templates-using-python-cb039ea2c890
#https://docxtpl.readthedocs.io/en/latest/

#pip install docxtpl

from docxtpl import DocxTemplate

doc = DocxTemplate("my_word_template.docx")

context = { 'company_name' : "World company" }

doc.render(context)

doc.save("generated_doc.docx")

