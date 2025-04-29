from typing import Generator
import re

def find_last_match(text: str, start: int, end: int, pattern: str) -> int:
    """
    Finds the last match of the pattern in the text between start and end indices.
    Returns the index of the last match or -1 if no match is found.
    """
    matches = list(re.finditer(pattern, text[start:end]))
    if matches:
        return start + matches[-1].start()
    return None

def find_last_match_multiple(text: str, start: int, end: int, patterns: list[str]) -> int:
    """
    Finds the last match of any pattern in the patterns list within the text between start and end indices.
    Returns the index of the last match or -1 if no match is found.
    """
    for pattern in patterns:
        last_index = find_last_match(text, start, end, pattern)
        if last_index:
            return last_index
    return end

def text_to_chunks(text: str, max_char: int = 5000, patterns: list[str] = [r"\n\n", r"\n", r"\s"]) -> Generator[str, None, None]:
    """
    Splits the text into chunks of max_char length and yields them as a generator.
    """
    start = 0
    max_end = start + max_char

    while start < len(text):
        if max_end >= len(text):
            yield text[start:].strip()
            break

        # Find the last match of any pattern in the range
        last_match = find_last_match_multiple(text, start + 1, max_end, patterns)
        
        yield text[start:last_match].strip()
        start = last_match
        max_end = start + max_char

if __name__ == "__main__":
    text = "This is a test text.\n\nRandom text to split.\n\nAnother line of text.\n\nAnd another one.\n\n"
    chunks = text_to_chunks(text, 5)
    for chunk in chunks:
        print(chunk)