#!/usr/bin/env python3
"""Check DeltaSync planning records without editing files or running product tests."""

import argparse
from collections import Counter
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


TASK_ID = r"[A-Z]+-\d+[a-z]?"
STATES = {
    "planejada", "pronta", "em andamento", "em revisão",
    "em validação", "bloqueada", "concluída",
}
ACTIVE = {"em andamento", "em revisão", "em validação"}
SKILLS = {
    "plan-reader", "plan-implementer", "code-reviewer",
    "plan-validator", "plan-maintainer",
}


def outside_fences(text):
    """Keep line boundaries while excluding Markdown examples and code blocks."""
    lines, fence = [], None
    for line in text.splitlines():
        marker = re.match(r"^\s*(`{3,}|~{3,})(.*)$", line)
        if marker:
            run, suffix = marker.groups()
            if fence is None:
                fence = run
            elif run[0] == fence[0] and len(run) >= len(fence) and not suffix.strip():
                fence = None
            lines.append("")
        else:
            lines.append(line if fence is None else "")
    return "\n".join(lines)


def field(text, name):
    match = re.search(rf"^{re.escape(name)}: ([^\n]+)$", text, re.MULTILINE)
    return match[1].strip() if match else ""


def anchors(text):
    result = set(re.findall(r'<a\s+id="([^"]+)"', text))
    counts = Counter()
    for heading in re.findall(r"^#+\s+(.+)$", text, re.MULTILINE):
        slug = re.sub(r"[^\w\s-]", "", heading.lower())
        slug = re.sub(r"\s", "-", slug)
        number = counts[slug]
        counts[slug] += 1
        result.add(slug if number == 0 else f"{slug}-{number}")
    return result


def check(root, *, allow_missing_tcc_reference=False):
    errors = []
    plan = root / "plan"
    required = [root / p for p in (
        "AGENTS.md", "README.md", "proposta.md", "plan/README.md",
        "plan/TRACEABILITY.md", "plan/DECISIONS.md", "plan/RISKS.md",
    )]
    required += [root / f".agents/skills/{name}/SKILL.md" for name in SKILLS | {"plan-executor"}]
    for file in required:
        if not file.is_file():
            errors.append(f"Arquivo obrigatório ausente: {file.relative_to(root)}")
    if errors:
        return errors, {}, 0

    docs = set(required) | set(plan.rglob("*.md")) | set((root / ".agents/skills").rglob("*.md"))
    texts = {file: outside_fences(file.read_text(encoding="utf-8")) for file in docs}
    link_count = 0
    for file, text in texts.items():
        for raw in re.findall(r"\[[^\]]*\]\((<[^>]+>|[^)]+)\)", text):
            target = raw.removeprefix("<").removesuffix(">")
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc:
                continue
            destination = (file.parent / unquote(parsed.path)).resolve() if parsed.path else file
            link_count += 1
            if not destination.exists():
                if (allow_missing_tcc_reference
                        and destination == (root / "referencia/Proposta TCC.pdf").resolve()):
                    continue
                errors.append(f"{file.relative_to(root)}: link ausente {target}")
            elif parsed.fragment and destination.is_file():
                content = texts.get(destination)
                if content is None:
                    content = outside_fences(destination.read_text(encoding="utf-8"))
                if unquote(parsed.fragment) not in anchors(content):
                    errors.append(f"{file.relative_to(root)}: anchor ausente {target}")

    for skill in sorted((root / ".agents/skills").glob("*/SKILL.md")):
        raw = skill.read_text(encoding="utf-8")
        front = re.match(r"\A---\n(.*?)\n---(?:\n|$)", raw, re.DOTALL)
        if not front or field(front[1], "name") != skill.parent.name or not field(front[1], "description"):
            errors.append(f"{skill.relative_to(root)}: name/description inválidos")

    tasks = {}
    phase_texts = {file: texts[file] for file in sorted(plan.glob("*PHASE*.md"))}
    for file, text in phase_texts.items():
        headings = list(re.finditer(rf"^## ({TASK_ID}) — ([^\n]+)$", text, re.MULTILINE))
        for heading in headings:
            task_id, title = heading.groups()
            end = re.search(r"^## ", text[heading.end():], re.MULTILINE)
            body = text[heading.end():heading.end() + end.start()] if end else text[heading.end():]
            status, priority, dependencies = (field(body, name) for name in ("Status", "MoSCoW", "Dependências"))
            if task_id in tasks:
                errors.append(f"Tarefa duplicada: {task_id}")
            if status not in STATES or priority not in {"MUST", "SHOULD", "COULD", "WON'T-YET"} or not dependencies:
                errors.append(f"{task_id}: metadados inválidos")
            tasks[task_id] = {
                "file": file, "title": title, "status": status, "priority": priority,
                "dependencies": [] if dependencies == "nenhuma" else dependencies.split(", "),
                "body": body,
            }
    if not tasks:
        errors.append("Plano sem tarefas reconhecidas")

    index = texts[plan / "README.md"]
    indexed = set()
    pattern = rf"^\| \[({TASK_ID})\]\(([^)]+)\) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$"
    for match in re.finditer(pattern, index, re.MULTILINE):
        task_id, target, title, status, priority, dependencies = match.groups()
        if task_id in indexed:
            errors.append(f"Índice duplicado: {task_id}")
        indexed.add(task_id)
        task = tasks.get(task_id)
        if not task:
            errors.append(f"Tarefa do índice sem definição: {task_id}")
            continue
        expected = (f"{task['file'].relative_to(plan).as_posix()}#{task_id.lower()}", task["title"], task["status"], task["priority"], ", ".join(task["dependencies"]) or "—")
        if tuple(value.strip() for value in (target, title, status, priority, dependencies)) != expected:
            errors.append(f"Índice e fase discordam: {task_id}")
    for task_id in tasks.keys() - indexed:
        errors.append(f"Tarefa sem índice: {task_id}")

    visited = set()

    def walk(task_id, active):
        if task_id in active:
            errors.append(f"Ciclo de dependências: {task_id}")
            return
        if task_id in visited or task_id not in tasks:
            return
        active.add(task_id)
        for dependency in tasks[task_id]["dependencies"]:
            walk(dependency, active)
        active.remove(task_id)
        visited.add(task_id)

    ledger = texts[plan / "TRACEABILITY.md"]
    records = {}
    for match in re.finditer(rf"^## Execução ({TASK_ID}) — ([^\n]+)\n(.*?)(?=^## |\Z)", ledger, re.MULTILINE | re.DOTALL):
        task_id, _, body = match.groups()
        if task_id not in tasks:
            errors.append(f"Registro de execução sem tarefa: {task_id}")
        records[task_id] = body

    for task_id, task in tasks.items():
        walk(task_id, set())
        for dependency in task["dependencies"]:
            if dependency not in tasks:
                errors.append(f"{task_id}: dependência desconhecida {dependency}")
            elif task["status"] in ACTIVE | {"pronta", "concluída"} and tasks[dependency]["status"] != "concluída":
                errors.append(f"{task_id}: dependência não concluída {dependency}")
        if task["status"] != "concluída":
            continue
        boxes = re.findall(r"^- \[([ xX])\]", task["body"], re.MULTILINE)
        if not boxes or " " in boxes:
            errors.append(f"{task_id}: conclusão com critérios abertos ou ausentes")
        if "Evidência de conclusão: ainda não registrada" in task["body"]:
            errors.append(f"{task_id}: campo de evidência ainda pendente na fase")
        record = records.get(task_id, "")
        for name, value in {"Status final": "concluída", "Review": "aprovado", "Validação": "aprovada"}.items():
            if field(record, name) != value:
                errors.append(f"{task_id}: registro de conclusão sem {name}: {value}")
        if not SKILLS <= set(field(record, "Skills").split(", ")):
            errors.append(f"{task_id}: cinco skills não registradas")
        for name in ("Leitura", "Implementação", "Achados", "Comandos", "Critérios", "Manutenção", "Limitações"):
            if not field(record, name):
                errors.append(f"{task_id}: evidência sem campo {name}")

    active_tasks = [task_id for task_id, task in tasks.items() if task["status"] in ACTIVE]
    current = re.search(r"Tarefa ativa: \*\*([^*]+)\*\*", index)
    if len(active_tasks) > 1 or not current or current[1] != (active_tasks[0] if active_tasks else "nenhuma"):
        errors.append("Campo Tarefa ativa inconsistente ou múltiplas tarefas ativas")

    for file, text in phase_texts.items():
        if re.match(r"concluída(?:[.\s]|$)", field(text, "Estado")) and any(task["priority"] == "MUST" and task["status"] != "concluída" for task in tasks.values() if task["file"] == file):
            errors.append(f"{file.name}: fase concluída com MUST pendente")

    gate_dependencies = set()

    def closure(task_id):
        for dependency in tasks.get(task_id, {}).get("dependencies", []):
            if dependency not in gate_dependencies:
                gate_dependencies.add(dependency)
                closure(dependency)

    if "VAL-05" not in tasks:
        errors.append("Gate final VAL-05 ausente")
    closure("VAL-05")
    for task_id, task in tasks.items():
        if task_id != "VAL-05" and task["priority"] == "MUST" and task_id not in gate_dependencies:
            errors.append(f"Gate final não alcança MUST: {task_id}")
    return errors, tasks, link_count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--allow-missing-tcc-reference", action="store_true",
                        help="Allow only the absent local referencia/Proposta TCC.pdf in public CI")
    args = parser.parse_args()
    try:
        errors, tasks, links = check(args.root.resolve(), allow_missing_tcc_reference=args.allow_missing_tcc_reference)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Falha ao ler plano: {error}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"ERRO: {error}", file=sys.stderr)
        return 1
    ready = ", ".join(task_id for task_id, task in tasks.items() if task["status"] == "pronta") or "nenhuma"
    print(f"Plano consistente: {len(tasks)} tarefas, {links} links locais. Prontas: {ready}.")
    print("Checagem estrutural; qualidade das evidências e testes exigem validação do agente.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
