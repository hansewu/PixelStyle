/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:t; tab-width:2; c-basic-offset: 2 -*- */
/*
 #
 #  File        : gmic_parser.h
 #
 #  Description : A self-contained header file with helper functions to
 #                parse the G'MIC standard library file into a param structure
 #
 #  Copyright   : Tobias Fleischer / reduxFX Productions (http://www.reduxfx.com)
 #
 #  Licenses        : This file is 'dual-licensed', you have to choose one
 #                    of the two licenses below to apply.
 #
 #                    CeCILL-C
 #                    The CeCILL-C license is close to the GNU LGPL.
 #                    ( http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html )
 #
 #                or  CeCILL v2.0
 #                    The CeCILL license is compatible with the GNU GPL.
 #                    ( http://www.cecill.info/licences/Licence_CeCILL_V2-en.html )
 #
 #  This software is governed either by the CeCILL or the CeCILL-C license
 #  under French law and abiding by the rules of distribution of free software.
 #  You can  use, modify and or redistribute the software under the terms of
 #  the CeCILL or CeCILL-C licenses as circulated by CEA, CNRS and INRIA
 #  at the following URL: "http://www.cecill.info".
 #
 #  As a counterpart to the access to the source code and  rights to copy,
 #  modify and redistribute granted by the license, users are provided only
 #  with a limited warranty  and the software's author,  the holder of the
 #  economic rights,  and the successive licensors  have only  limited
 #  liability.
 #
 #  In this respect, the user's attention is drawn to the risks associated
 #  with loading,  using,  modifying and/or developing or reproducing the
 #  software by the user in light of its specific status of free software,
 #  that may mean  that it is complicated to manipulate,  and  that  also
 #  therefore means  that it is reserved for developers  and  experienced
 #  professionals having in-depth computer knowledge. Users are therefore
 #  encouraged to load and test the software's suitability as regards their
 #  requirements in conditions enabling the security of their systems and/or
 #  data to be ensured and,  more generally, to use and operate it in the
 #  same conditions as regards security.
 #
 #  The fact that you are presently reading this means that you have had
 #  knowledge of the CeCILL and CeCILL-C licenses and that you accept its terms.
 #
*/


#include "gmic_parser.h"

#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

#include "RFX_StringUtils.h"

using namespace std;
using namespace reduxfx;

namespace reduxfx {

static const char* const src_prefix_old_c = "#@gimp";
static const char* const src_prefix_c = "#@gui";
static const char* const dst_prefix_c = "#@gmic_plugin";
//static const char* const master_name_c = "gmic_ae";


static
string getUniqueId(const string& name)
{
	string uniqueid = "";
	for (unsigned int i = 0; i < name.size(); i++) {
		if ((name[i] >= 'a' && name[i] <= 'z')
			|| (name[i] >= 'A' && name[i] <= 'Z')
			|| (name[i] >= '0' && name[i] <= '9'))
			uniqueid += name[i];
	}
    // The recommended format is the reverse domain name format of the developer, for example "uk.co.thefoundry", followed by the developer's unique name for the plug-in. e.g. "uk.co.thefoundry.F_Kronos".
	return "eu.gmic." + uniqueid;
}

static
void processCommand(const string& s, EffectData& cd)
{
	const string dst_prefix = dst_prefix_c;
	string r = s;
	if (r == dst_prefix + " :") return;
	r = strRemoveXmlTags(r, false);
	int sPos = (int)r.find(":");
	if (sPos < 0) return;
	string r1 = r.substr(0, sPos - 1);
	int sPos2 = (int)r1.find(dst_prefix);
	if (sPos2 >= 0) cd.name = strTrim(r1.substr(sPos2 + dst_prefix.size()), " \n");

	string r2 = r.substr(sPos + 1);
	string r3 = r2;
	sPos = (int)r2.find(",");
	if (sPos >= 0) {
		r3 = r2.substr(sPos + 1);
		r2 = r2.substr(1, sPos - 1);
	}
	strReplace(r3, "(0)", "");
	strReplace(r3, "(1)", "");
	strReplace(r3, "(2)", "");
	strReplace(r3, "+", "");

	sPos = (int)r2.find("_none_");
	if (sPos >= 0) r2 = r3;
	sPos = (int)r3.find("_none_");
	if (sPos >= 0) r3 = r2;

	cd.command = strTrim(r2, " \n");
	cd.preview_command = strTrim(r3, " \n");
	if (cd.preview_command == "") cd.preview_command = cd.command;
}

static
void processParam(const string& s, EffectParameter& cp)
{
	string r = s;
	cp.minValue = "";
	cp.maxValue = "";
	cp.defaultValue = "";
	cp.text = "";
	int p1 = (int)r.find(":");
	int p2 = (int)r.find("=");
	if (p2 < 0) return;
	if (p1 > p2) {
		// ":" should be before "="
		p1 = -1;
	}
	cp.name = strTrim(r.substr(p1 + 1, p2 - p1 - 2));
	r = strTrim(r.substr(p2 + 1));
	p1 = (int)r.find_first_of("([{");
	if (p1 < 0) return;
	cp.paramType = strTrim(r.substr(0, p1));
	strReplace(cp.paramType, "_", "");
	cp.paramType = strLowercase(cp.paramType);
	string pval = strTrim(r.substr(p1 + 1));
	pval = pval.substr(0, pval.size() - 1);
	strLowercase(pval);
	strReplace(pval, "true", "1");
	strReplace(pval, "false", "0");

	// For parameters description, see "Specific rules for the universal plug-in"
	// in the gmic_stdlib.gmic file in the G'MIC sources.
	if (cp.paramType == "bool") {
		// 'bool(default_value={ 0 | 1 | false | true })'
		// Add a boolean parameter (0 or 1) (as a checkbutton).
		cp.defaultValue = pval;
		cp.minValue = "0";
		cp.maxValue = "1";
	} else if (cp.paramType == "button") {
		// 'button(_alignment)'
		// Add a boolean parameter (0 or 1) (as a button).
		cp.paramType = "bool";
		cp.minValue = "0";
		cp.maxValue = "1";
		cp.defaultValue = "0";
	} else if (cp.paramType == "choice") {
		// 'choice(_default_indice,Choice0,..,ChoiceN)'
		// Add a integer parameter (as a combobox).
		p1 = (int)pval.find(",");
		p2 = (int)pval.find("\"");
		if (p1 < p2) {
			cp.defaultValue = pval.substr(0, p1);
			cp.text = pval.substr(p1 + 1);
		} else {
			cp.defaultValue = "0";
			cp.text = pval;
		}
		vector<string> c;
		strSplit(cp.text, ',', c);
		cp.text = "";
		for (int i = 0; i < (int)c.size() - 1; i++) {
			cp.text += strTrim(c[i]) + "|";
		}
		cp.text += strTrim(c[(int)c.size() - 1]);
		strReplace(cp.text, "\"", "");
		cp.minValue = "0";
		cp.maxValue = intToString((int)c.size() - 1);
	} else if (cp.paramType == "color") {
		// 'color(R,_G,_B,_A)'
		// Add R,G,B[,A] parameters (as a colorchooser).
		cp.defaultValue = pval;
		strReplace(cp.defaultValue, ",", "|");
	} else if (cp.paramType == "point") {
		// 'point(_X,_Y,_removable={ -1 | 0 | 1 },_burst={ 0 | 1 },_R,_G,_B,_[-]A,_radius%,_is_visible={ 0 | 1 })'
		// Add X,Y parameters (as a moveable point over the preview)
		p1 = (int)pval.find(",");
		p2 = (int)pval.find(",", p1 + 1);
		if (p2 != (int)std::string::npos) { // ignore everything except the default value
			cp.defaultValue = pval.substr(0, p2);
		} else {
			cp.defaultValue = pval;
		}
		strReplace(cp.defaultValue, ",", "|");
	} else if (cp.paramType == "value") {
		// 'value(value)'
		// Add a pre-defined value parameter (not displayed).
		cp.defaultValue = pval;
	} else if (cp.paramType == "file") {
		// 'file[_in,_out](_default_filename)'
		// Add a filename parameter (as a filechooser).
//		cp.paramType = "text";
		cp.text = strTrim(pval, "\"");
		if (cp.text == "") cp.text = "test.txt";
		cp.defaultValue = cp.text;
	} else if (cp.paramType == "float" || cp.paramType == "int") {
		// 'float(default_value,min_value,max_value)'
		// Add a float-valued parameter (as a float slider).
		// 'int(default_value,min_value,max_value)'
		// Add a integer parameter (as an integer slider).
		p1 = (int)pval.find(",");
		p2 = (int)pval.rfind(",");
		if (p1 == p2) {
			cp.minValue = pval.substr(0, p1);
			cp.maxValue = pval.substr(p1);
			cp.defaultValue = cp.minValue;
		} else {
			cp.defaultValue = pval.substr(0, p1);
			cp.maxValue = pval.substr(p2 + 1);
			cp.minValue = pval.substr(p1 + 1, p2 - p1 - 1);
		}
	} else if (cp.paramType == "folder") {
		// 'folder(_default_foldername)'
		// Add a foldername parameter (as a folderchooser).
//		cp.paramType = "text";
		cp.text = strTrim(pval, "\"");
		if (cp.text == "") cp.text = "./";
		cp.defaultValue = cp.text;
	} else if (cp.paramType == "link") {
		// 'link(_alignment,_label,URL)'
		// Display a URL (do not add a parameter).
		p1 = (int)pval.find(",");
		p2 = (int)pval.find(",", p1 + 1);
		if (p2 != (int)std::string::npos) {
			// alignment, label, URL
			cp.text = strTrim(pval.substr(p1+1, p2-1), " \t\r\n'\"") + ": " + strTrim(pval.substr(p2+1), " \t\r\n'\"");
		} else if (p1 != (int)std::string::npos) {
			// label, URL
			cp.text = strTrim(pval.substr(0, p1-1), " \t\r\n'\"") + ": " + strTrim(pval.substr(p1+1), " \t\r\n'\"");
		} else {
			// URL
			cp.text = strTrim(pval, " \t\r\n'\"");
		}
		strReplace(cp.text, ",", ": ");
	} else if (cp.paramType == "note") {
		// 'note(_label)'
		// Display a label (do not add a parameter).
		cp.text = pval;
	} else if (cp.paramType == "text") { // || cp.paramType == "flags") {
		// 'text(_is_multiline={ 0 | 1 },_default text)'
		// Add a single or multi-line text parameter (as a text entry).
		p1 = (int)pval.find(",");
		p2 = (int)pval.find("\"");
		if (p1 >= 0 && p1 < p2) {
			cp.maxValue = pval.substr(0, p1);
			pval = pval.substr(p1 + 1);
		} else {
			cp.maxValue = "0";
		}
		cp.text = strTrim(pval, "\"");
		cp.defaultValue = cp.text;
	} else if (cp.paramType == "separator") {
		// 'separator()'
		// Display an horizontal separator (do not add a parameter).Add a single or multi-line text parameter (as a text entry).
		(void)0;
	} else if (cp.paramType == "input") {
		// ???? not in the G'MIC doc (see gmic_stdlib.gmic)
		cp.defaultValue = strTrim(pval, "\"");
	}
}

string gmic_parse_single(const string& content, EffectData& cd)
{
	const string src_prefix_old = src_prefix_old_c;
	const string src_prefix = src_prefix_c;
	const string src_prefix_en = src_prefix + "_en";
	const string dst_prefix = dst_prefix_c;
	const string dst_prefix_en = dst_prefix + "_en";
	string result;
	bool inMulti = false;
	std::string inMultiClose = "";
	cd.name = "";
	cd.command = "";
	cd.preview_command = "";
	cd.notes = "";
	cd.param.clear();

	vector<string> lines;
	strSplit(content, '\n', lines);
	for (int i = 0; i < (int)lines.size(); i++) {
		//printf("[%d]: %s\n", i,lines[i].c_str());
		string line = strTrim(lines[i], " \r\n\t");
        // TODO: there should be a "while" loop here, in case there are several parameters on the line
		if (line.size() > 0 && line[0] != '#') result += line + "\n";
		strReplace(line, src_prefix_old, dst_prefix);
		strReplace(line, src_prefix_en, dst_prefix);
		strReplace(line, src_prefix, dst_prefix);
		strReplace(line, dst_prefix_en, dst_prefix);
		string n = strTrim(line, " \r\n\t");
		int sPos = (int)line.find(":");
		int sPos2 = (int)line.find("#");
		if (sPos >= 0 && sPos2 == 0) {
			if (line.substr(0, dst_prefix.size() + 3) != dst_prefix + " : ") {
				processCommand(line, cd);
			} else {
				strReplace(line, dst_prefix + " : ", "");
				while (!line.empty()) {
					if (inMulti) {
						string &name = cd.param[cd.param.size() - 1].name;
						// Only add a space if the previous line does not end with "\n" or "\"
						// (see eg. the "Privacy Notice" in gmic_stdlib.gmic)
						if (name.size() < 2 ||
							!(name[name.size()-2] == '\\' && name[name.size()-1] == 'n') ||
							!(name[name.size()-1] == '\\')) {
							cd.param[cd.param.size() - 1].name += ' ';
						}
						int pEnd = (int)line.find(inMultiClose);
						if (pEnd > 0) {
							cd.param[cd.param.size() - 1].name += line.substr(0, pEnd + 1);
							inMulti = false;
							line = strTrim(line.substr(pEnd));
						} else {
							cd.param[cd.param.size() - 1].name += line;
							line.clear();
						}
						continue;
					}
					int ePos = (int)line.find("=");
					if (ePos < 0) {
						// garbage?
						line.clear();
						continue;
					} else {
						int pStart = (int)line.find_first_of("([{", ePos + 1);
						int pEnd = -1;
						if (pStart > 0) {
							if (line[pStart] == '(') {
								inMultiClose = ")";
							} else if (line[pStart] == '[') {
								inMultiClose = "]";
							} else if (line[pStart] == '{') {
								inMultiClose = "}";
							} 
							pEnd = (int)line.find(inMultiClose, pStart + 1);

							if (pEnd > 0) {
								// there is one more param
								EffectParameter p;
								p.name = line.substr(0, pEnd+1);
								//std::cout << p.name << std::endl;
								cd.param.push_back(p);
								line = strTrim(line.substr(pEnd + 1), ", ");
								if (!line.empty()) {
									line = dst_prefix + " : " + line;
								}
							} else {
								// multi-line
								EffectParameter p;
								p.name = line;
								cd.param.push_back(p);
								inMulti = true;
								line.clear();
							}
						}
					}
				}
			}
		} else if (sPos2 == 0) {
			sPos = (int)n.find(" ");
			if (sPos >= 0) {
				n = n.substr(sPos);
				n = strRemoveXmlTags(n, false);
				strReplace(n, " & ", " and ");
				n = strTrim(n, " \r\n\t_");
				if (n != "") {
					cd.category = n;
				}
			}
		}
	}
	for (int i = 0; i < (int)cd.param.size(); i++) {
		processParam(cd.param[i].name, cd.param[i]);
		bool ok = false;
		int cnt = 2;
		string t = cd.param[i].name;
		while (!ok) {
			ok = true;
			for (int j = 0; j < i; j++) {
				if (cd.param[j].name == cd.param[i].name) {
					cd.param[i].name = t + "_" + intToString(cnt++);
					ok = false;
					break;
				}
			}
		}
	}
	if ((int)content.find(" layers") > 0)
		cd.multiLayer = true;
	else
		cd.multiLayer = false;
	cd.notes = strTrim(cd.notes, "\n");

	cd.name = strRemoveXmlTags(cd.name, true);
	cd.category = strRemoveXmlTags(cd.category, true);
	cd.notes = strRemoveXmlTags(cd.notes, true);
	cd.uniqueId = getUniqueId(cd.name);

	return result;
}

void gmic_parse_multi(const string& content, vector<EffectData>* cds, vector<string>* lines)
{
	const string src_prefix_old = src_prefix_old_c;
	const string src_prefix = src_prefix_c;
	const string dst_prefix = dst_prefix_c;
	stringstream ss(content);
	string line, cat, command;
	vector<string> commands;
	EffectData cd;
	//printf("content:\n%s\n", content.c_str());
	while (getline(ss, line)) {
		//printf("%s\n%s\n", cat.c_str(), line.c_str());
		if ( (line.substr(0, src_prefix.size() + 1) == src_prefix + " ") ||
			 (line.substr(0, src_prefix.size() + 4) == src_prefix + "_en ") ||
			 (line.substr(0, src_prefix_old.size() + 1) == src_prefix_old + " ") ) {
			// This is a @gui line or equivalent.
			// Three possibilities:
			// "#@gui Folder name" -> new category
			// "#@gui Command name : ..." -> new plugin
			// "#@gui : ..." -> plugin parameters description
			string::size_type spc = line.find(' ');
			if (spc != string::npos && line[spc+1] == ':') {
				// plugin parameters description
				command += '\n' + line;
			} else {
				string::size_type col = line.find(':', spc + 1);
				if (col == string::npos) {
					// new Folder/category
					if (!command.empty()) {
						commands.push_back(cat + '\n' + command);
						command.clear();
					}
					cat = line;
					if (cat == "#@gui ____<i>About</i>") {
						command = "#@gui About G'MIC : fx_gmicky, fx_gmicky_preview";
					}
				} else if (col != spc + 1) {
					if (cat == "#@gui ____<i>About</i>") {
						// add new title
						command += "\n#@gui : note = note{" + line.substr(spc+1, col - spc - 1) + '}';
					} else {
						// new command/Plugin
						if (!command.empty()) {
							commands.push_back(cat + '\n' + command);
							command.clear();
						}
						command = line;
					}
				}
			}
		}
	}
	// push last command being processed
	if (!command.empty()) {
		commands.push_back(cat + '\n' + command);
		command.clear();
	}

	for (vector<string>::const_iterator it = commands.begin(); it != commands.end(); ++it) {
		string line2 = *it;
		strReplace(line2, src_prefix, dst_prefix);
		strReplace(line2, src_prefix_old, dst_prefix);
		gmic_parse_single(line2, cd);
		//printf("%s/%s\n", cd.category.c_str(), cd.name.c_str());
		bool doOutput = true;
		// skip entries from the about category
		if (cd.category == "About" && cd.uniqueId != "eu.gmic.AboutGMIC") {
			//doOutput = false;
		} else if (cd.category == "Various") {
			//doOutput = false;
			doOutput = true;
		} else if ((int)strLowercase(line2).find("[interactive]") >= 0) {
			doOutput = false;
		} else if (cd.category == "Sequences" || (int)strLowercase(line2).find("[animated]") >= 0) {
			doOutput = false;
		}
		if (doOutput && !cd.name.empty()) {
			if (cds) cds->push_back(cd);
			if (lines) lines->push_back(line2);
		}
	}
	if (!cds) {
		return;
	}
    for (vector<EffectData>::iterator it = cds->begin(); it != cds->end(); ++it) {
        // post-process
        EffectData& cd = *it;
        if (cd.category == "About") {
            cd.category = "GMIC";
        } else {
            cd.category = "GMIC/" + cd.category;
            cd.name = "G'MIC " + cd.name;
        }
        strReplace(cd.name, "[", "");
        strReplace(cd.name, "]", "");
        strReplace(cd.name, " - ", " ");
        strReplace(cd.name, "inverse", "inv.");
    }
}

}
