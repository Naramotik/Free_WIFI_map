package com.example.demo.dto;

import com.example.demo.model.Mark;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MarkToPost {
    Mark mark;
    String email;
}
