from ollama import chat
from pydantic import BaseModel
from json import loads, dumps
from tqdm import tqdm
from llmlong.text_to_chunks import text_to_chunks
from typing import Literal

def structured_extract_from_chunk(prompt: str, text: str, structure, model: str = 'gemma3:4b') -> dict:
    prompt = f'''
        {prompt}

        The text is: 
        ```
        {text}
        ```
    '''
    
    response = chat(
        messages=[
            {
                'role': 'user',
                'content': prompt
            }
        ],
        model=model,
        format=structure.model_json_schema(),
    )

    
    try:
        answer = structure.model_validate_json(response.message.content).model_dump()
        answer['text_length'] = len(text)
        return answer
    except Exception as e:
        return {
            'text_length': len(text)
        }
    
def structured_extract_from_longtext(prompt: str, text: str, structure, model: str = 'gemma3:4b', max_char: int = 5000) -> list[dict]:
    """
    Splits the text into chunks and gets the sentiment for each chunk.
    """
    answers = []
    for chunk in text_to_chunks(text, max_char = max_char):
        chunk_answer = structured_extract_from_chunk(prompt, chunk, structure, model)
        answers.append(chunk_answer)
    
    return answers

def main():
    example = '''
    Marcell said that this is a pretty long text.
    Ben is not sure about that.
    Ivan told me we should split it!
    '''

    class Speaker(BaseModel):
        name: str
        gender: Literal['male', 'female', 'other']
    
    output = structured_extract_from_longtext('Identify the speakers and their gender', example, Speaker, max_char=55)
    print(output)

if __name__ == "__main__":
    main()