import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=name=>JSON.parse(fs.readFileSync(path.join(root,'artifacts',`domain-eval-${name}.json`),'utf8').replace(/^\uFEFF/,''));
const before=read('before'),after=read('after'),heldout=read('heldout'),all=[...after,...heldout];
const text=[`# 五领域本机翻译评测（2026-10-15）

当前模型仍为本机 Hy-MT2-1.8B Q4_K_M，没有更换模型或上传文档。本报告使用自行编写的合成句子，不包含用户论文。

15 条开发样例做了旧版／新版对照；另外 10 条补充样例在最终提示确定后运行，没有再据其结果调整本轮提示。它们都由同一开发助手编写，属于开发验证，不是独立专家盲评，也不覆盖真实论文复杂性。

新版共 ${all.length} 条结果，其中 ${all.filter(x=>x.errors.length).length} 条触发阻止回填错误，${all.filter(x=>x.warnings.length).length} 条出现复核提示。**这些是规则检测结果，不是翻译准确率。** 另有 49 项核心回归断言通过，Word 前端保护及服务接口另行测试。

## 已观察到的改善

- 旧版 med-03、pet-01、pet-03 翻译了背景说明，漏掉原文；新版这三句均恢复原文的对象和数值。
- cs-02 的 data competition 改为 data races；并发与并行、否定条件仍保留。
- 油气样例区分 water cut 与 water saturation；计算机样例保留大小写敏感代码。
- 参考术语是建议译法；用户／论文锁定术语优先，避免把内置参考当作绝对唯一译法。

## 仍需改进和复核的地方

- pet-02 的“尚不能”仍未明确译出 yet；新版规则给出时间范围警告。这一句不能算完全解决。
- med-h1 使用 has not been evaluated，已在一定程度表达至今未评估；时间范围规则仍提示复核，说明规则可能误报。
- med-h2 的 no statistical difference 不如 no statistically significant difference 精确。
- pet-h2 的 m³/d 保留正确，但 volume 宜根据上下文写成 injection/production rate，以明确流量；现有规则不能识别这种语义细节。
- civil-h2 原文的“并未消除”偏向已经观察到的结果，而 does not eliminate 容易被理解成一般规律，应结合论文时态复核。
- chat-01 的 ten minutes later 不如 ten minutes late 清楚地表达“迟到十分钟”。
- 这些是开发助手逐句审阅意见，尚未经过医学、土木、计算机和油气专家审校。规则也不能全面检测对象与数值对调、范围限制或漏译。

## 使用与后续评测

在 Word 侧栏／工作台选择医学、土木工程、计算机、油气开采或日常交流。按论文维护术语，展开“查看或补充上下文”，填写研究对象／实验条件／缩写含义并勾选启用。输入法即时翻译仍默认日常交流；论文请用领域侧栏。

下一阶段应收集每领域由作者确认的代表性段落，覆盖不同子学科与复杂句；由领域人员盲评原文保真、术语、增漏译、数值对应、英文可读性和修改量。可比较现有模型与更大本地模型，但不能根据参数量或本报告样例宣布准确率提高。

## 官方参考资料

- [Hy-MT2 官方模型卡](https://huggingface.co/tencent/Hy-MT2-1.8B)：支持术语、风格与背景信息指令；本轮对齐了上下文与翻译请求的顺序。公开模型成绩不能代替本机量化模型的领域实测。
- [NCI progression-free survival](https://www.cancer.gov/publications/dictionaries/cancer-terms/def/progression-free-survival)：医学术语核对示例。
- [SLB water saturation](https://glossary.slb.com/en/terms/w/water_saturation)、[SLB permeability](https://glossary.slb.com/Terms/p/permeability)：油气概念消歧参考。

## 逐条结果
`];
for(const row of all){
 const old=before.find(x=>x.id===row.id);
 text.push(`### ${row.id} · ${row.domain}\n\n原文：${row.source}\n\n背景：${row.context||''}\n\n核对重点：${row.review}\n${old?`\n旧版：${old.translation||'未返回译文'}\n`:''}\n新版：${row.translation||'未返回译文'}\n\n规则结果：${[...row.errors,...row.warnings].join('；')||'未发现规则违规，不代表语义完全正确。'}\n`);
}
fs.writeFileSync(path.join(root,'artifacts','五领域翻译评测.md'),text.join('\n'),'utf8');
console.log(`Report written: ${after.length} comparison cases + ${heldout.length} additional cases; ${all.filter(x=>x.errors.length).length} blocking errors; ${all.filter(x=>x.warnings.length).length} warnings.`);
